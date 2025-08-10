# app.py
import time
from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import JSONResponse
from fastapi.concurrency import run_in_threadpool
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeoutError

app = FastAPI(title="Mistral Playwright API", version="0.1")


def run_playwright_job(prompt: str, query: str, timeout_s: int = 60):
    start = time.time()
    combined = (prompt or "") + (query or "")

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
                args=[
                    "--disable-blink-features=AutomationControlled",
                    "--disable-dev-shm-usage",
                    "--no-sandbox",
                    "--disable-gpu",
                    "--disable-extensions",
                    "--disable-background-networking",
                    "--disable-sync",
                    "--disable-translate",
                    "--hide-scrollbars",
                    "--mute-audio",
                ],
            )
            page = browser.new_page()
            page.set_default_timeout(timeout_s * 1000)

            # load page and wait for network idle to avoid frame-detach errors
            page.goto("https://chat.mistral.ai/", wait_until="networkidle")

            # optional: press enter to ensure focus (matches your earlier script)
            try:
                page.keyboard.press("Enter")
            except Exception:
                pass

            # Wait for the real visible textarea (the one with placeholder containing 'anything')
            chat_input = page.locator("textarea[placeholder*='anything']").first
            chat_input.wait_for(state="visible", timeout=15000)
            chat_input.fill(combined)
            page.keyboard.press("Enter")

            # Wait for the assistant answer selector
            page.wait_for_selector(
                "div.flex.w-full.flex-col.gap-2.break-words div[data-message-part-type='answer']",
                timeout=timeout_s * 1000,
            )

            response_text = (
                page.locator(
                    "div.flex.w-full.flex-col.gap-2.break-words div[data-message-part-type='answer']"
                )
                .last
                .text_content()
            )

            browser.close()
    except PWTimeoutError as e:
        raise RuntimeError(f"Playwright timeout: {e}")
    except Exception as e:
        raise RuntimeError(f"Playwright error: {e}")

    elapsed = time.time() - start
    return {"response": response_text.strip() if response_text else "", "time_s": elapsed}


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/ask")
async def ask(
    query: str = Query(..., description="Query string to send to the model"),
    prompt: str = Query(
        "You are a research paper finder. Given a research paper name or query, search the web and return the most relevant paper (if exact match not found, return the closest match). Output only in JSON: {\"title\": \"<paper title>\", \"pdf_link\": \"<direct PDF link>\"}.",
        description="Optional system prompt prefix",
    ),
    timeout: int = Query(60, description="Timeout in seconds for the Playwright job"),
):
    """
    Example:
    GET /ask?query=Open%20agent%20architecture
    Optionally override prompt:
    GET /ask?query=foo&prompt=YOUR_PROMPT
    """
    if not query:
        raise HTTPException(status_code=400, detail="query is required")

    try:
        # run blocking Playwright job in a thread pool
        result = await run_in_threadpool(run_playwright_job, prompt, query, timeout)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    return JSONResponse(result)
