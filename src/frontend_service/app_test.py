# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from unittest.mock import AsyncMock, patch
from fastapi import FastAPI
import pytest
from main import init_app, lifespan
from agent import init_agent, user_agents
from langchain_core.messages import HumanMessage
import asyncio

CLIENT_ID = "test client id"
SECRET_KEY = "test_secret"
HISTORY = [HumanMessage(content="test")]


@pytest.fixture(scope="module")
def app():
    app = init_app(client_id=CLIENT_ID, secret_key=SECRET_KEY)
    if app is None:
        raise TypeError("app did not initialize")
    return app

@pytest.mark.asyncio
@patch("agent.init_agent")
async def test_lifespan(mock_init_agent):
    mock_init_agent.return_value = AsyncMock(agent=AsyncMock(ainvoke=AsyncMock()))
    app = FastAPI()
    async with lifespan(app):
        await asyncio.sleep(0.1)
    assert user_agents.get("test_uuid") is None


@pytest.mark.asyncio
@patch("agent.init_agent")
async def test_init_agent(mock_init_agent):
    mock_init_agent.return_value = AsyncMock(agent=AsyncMock(ainvoke=AsyncMock()))
    history = HISTORY
    user_agent = await init_agent(history)
    assert user_agent is not None
    assert user_agent.agent is not None
    assert user_agent.client is not None
