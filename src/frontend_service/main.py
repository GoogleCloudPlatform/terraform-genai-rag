# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio
import os
import uuid
from contextlib import asynccontextmanager
from typing import Any, Optional

import uvicorn
from fastapi import APIRouter, Body, FastAPI, HTTPException, Request
from fastapi.responses import PlainTextResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from langchain_core.messages import (
    AIMessage,
    BaseMessage,
    HumanMessage,
    message_to_dict,
    messages_from_dict,
    messages_to_dict,
)
from markdown import markdown
from starlette.middleware.sessions import SessionMiddleware

from agent import init_agent, user_agents

BASE_HISTORY: list[BaseMessage] = [
    AIMessage(content="I am an SFO Airport Assistant, ready to assist you.")
]
routes = APIRouter()
templates = Jinja2Templates(directory="templates")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # FastAPI app startup event
    print("Loading application...")
    yield
    # FastAPI app shutdown event
    close_client_tasks = [
        asyncio.create_task(a.client.close()) for a in user_agents.values()
    ]

    asyncio.gather(*close_client_tasks)


@routes.get("/")
@routes.post("/")
async def index(request: Request):
    """Render the default template."""
    # Agent setup
    agent = await get_agent(request.session, user_id_token=None)
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "messages": request.session["history"],
            "client_id": request.app.state.client_id,
        },
    )


@routes.post("/login/google", response_class=RedirectResponse)
async def login_google(
    request: Request,
):
    form_data = await request.form()
    user_id_token = form_data.get("credential")
    if user_id_token is None:
        raise HTTPException(status_code=401, detail="No user credentials found")
    # create new request session
    _ = await get_agent(request.session, str(user_id_token))
    print("Logged in to Google.")

    # Redirect to source URL
    source_url = request.headers["Referer"]
    return RedirectResponse(url=source_url)


@routes.post("/chat", response_class=PlainTextResponse)
async def chat_handler(request: Request, prompt: str = Body(embed=True)):
    """Handler for LangChain chat requests"""
    # Retrieve user prompt
    if not prompt:
        raise HTTPException(status_code=400, detail="Error: No user query")
    if "uuid" not in request.session:
        raise HTTPException(
            status_code=400, detail="Error: Invoke index handler before start chatting"
        )

    # Add user message to chat history
    request.session["history"].append(message_to_dict(HumanMessage(content=prompt)))
    user_agent = await get_agent(request.session, user_id_token=None)
    try:
        print(prompt)
        # Send prompt to LLM
        response = await user_agent.agent.ainvoke({"input": prompt})
        # Return assistant response
        request.session["history"].append(
            message_to_dict(AIMessage(content=response["output"]))
        )
        return markdown(response["output"])
    except Exception as err:
        raise HTTPException(status_code=500, detail=f"Error invoking agent: {err}")


async def get_agent(session: dict[str, Any], user_id_token: Optional[str]):
    global user_agents
    if "uuid" not in session:
        session["uuid"] = str(uuid.uuid4())
    id = session["uuid"]
    if "history" not in session:
        session["history"] = messages_to_dict(BASE_HISTORY)
    if id not in user_agents:
        user_agents[id] = await init_agent(messages_from_dict(session["history"]))
    user_agent = user_agents[id]
    if user_id_token is not None:
        user_agent.client.headers["User-Id-Token"] = f"Bearer {user_id_token}"
    return user_agent


@routes.post("/reset")
async def reset(request: Request):
    """Reset agent"""

    if "uuid" not in request.session:
        raise HTTPException(status_code=400, detail=f"No session to reset.")

    uuid = request.session["uuid"]
    global user_agents
    if uuid not in user_agents.keys():
        raise HTTPException(status_code=500, detail=f"Current agent not found")

    await user_agents[uuid].client.close()
    del user_agents[uuid]
    request.session.clear()


def init_app(client_id: Optional[str], secret_key: Optional[str]) -> FastAPI:
    # FastAPI setup
    app = FastAPI(lifespan=lifespan)
    app.state.client_id = client_id
    app.include_router(routes)
    app.mount("/static", StaticFiles(directory="static"), name="static")
    app.add_middleware(SessionMiddleware, secret_key=secret_key)
    return app


if __name__ == "__main__":
    PORT = int(os.getenv("PORT", default=8080))
    HOST = os.getenv("HOST", default="0.0.0.0")
    CLIENT_ID = os.getenv("CLIENT_ID")
    SECRET_KEY = os.getenv("SECRET_KEY")
    app = init_app(client_id=CLIENT_ID, secret_key=SECRET_KEY)
    if app is None:
        raise TypeError("app not instantiated")
    uvicorn.run(app, host=HOST, port=PORT)
