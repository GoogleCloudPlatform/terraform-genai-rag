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

from contextlib import asynccontextmanager
from ipaddress import IPv4Address, IPv6Address
from typing import Optional

import os
from fastapi import FastAPI
from langchain_google_vertexai import VertexAIEmbeddings
from pydantic import BaseModel

import datastore

from .routes import routes

EMBEDDING_MODEL_NAME = "textembedding-gecko@001"


class AppConfig(BaseModel):
    host: IPv4Address | IPv6Address = IPv4Address("127.0.0.1")
    port: int = 8080
    datastore: datastore.Config
    clientId: Optional[str] = None


def parse_config() -> AppConfig:
    config = {}
    config["host"] = os.environ.get("APP_HOST", "127.0.0.1")
    config["port"] = os.environ.get("APP_PORT", 8080)
    config["datastore"] = {}
    config["datastore"]["kind"] = os.environ.get(
        "DB_KIND", "cloudsql-postgres"
    )
    config["datastore"]["project"] = os.environ.get("DB_PROJECT", "my-project")
    config["datastore"]["region"] = os.environ.get("DB_REGION", "us-central1")
    config["datastore"]["instance"] = os.environ.get(
        "DB_INSTANCE", "my-instance"
    )
    config["datastore"]["database"] = os.environ.get(
        "DB_NAME", "assistantdemo"
    )
    config["datastore"]["user"] = os.environ.get("DB_USER", "postgres")
    config["datastore"]["password"] = os.environ.get("DB_PASSWORD", "password")
    return AppConfig(**config)


# gen_init is a wrapper to initialize the datastore during app startup
def gen_init(cfg: AppConfig):
    async def initialize_datastore(app: FastAPI):
        app.state.datastore = await datastore.create(cfg.datastore)
        app.state.embed_service = VertexAIEmbeddings(
            model_name=EMBEDDING_MODEL_NAME
        )
        yield
        await app.state.datastore.close()

    return asynccontextmanager(initialize_datastore)


def init_app(cfg: AppConfig) -> FastAPI:
    app = FastAPI(lifespan=gen_init(cfg))
    app.state.client_id = cfg.clientId
    app.include_router(routes)
    return app
