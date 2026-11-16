
import os
import secrets
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from openai import OpenAI

app = FastAPI(title="JARVIS AI")

API_KEY = os.getenv("OPENAI_API_KEY", "")
API_TOKEN = os.getenv("JARVIS_API_TOKEN", "")
MODEL = os.getenv("OPENAI_MODEL", "gpt-6-luna")


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=12000)
    history: list[dict] = []
    memory: str = ""
    web_search: bool = False


@app.get("/health")
def health():
    return {"status": "ok", "service": "JARVIS AI"}


@app.post("/chat")
def chat(data: ChatRequest, x_jarvis_token: str = Header(default="")):

    if not API_TOKEN or not secrets.compare_digest(
        x_jarvis_token, API_TOKEN
    ):
        raise HTTPException(status_code=401, detail="Invalid token")

    if not API_KEY:
        raise HTTPException(status_code=503, detail="API key missing")

    try:
        client = OpenAI(api_key=API_KEY)

        instructions = (
            "You are JARVIS, a friendly personal AI assistant. "
            "Answer clearly and helpfully. "
            "Never claim to perform actions you have not performed. "
            "User memory: " + data.memory
        )

        messages = []

        for item in data.history[-12:]:
            if item.get("role") in ["user", "assistant"]:
                messages.append({
                    "role": item["role"],
                    "content": item.get("content", "")
                })

        messages.append({
            "role": "user",
            "content": data.message
        })

        options = {
            "model": MODEL,
            "instructions": instructions,
            "input": messages,
            "max_output_tokens": 1200
        }

        if data.web_search:
            options["tools"] = [{"type": "web_search"}]

        response = client.responses.create(**options)

        return {"answer": response.output_text}

    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail="AI request failed: " + str(e)[:250]
        )
