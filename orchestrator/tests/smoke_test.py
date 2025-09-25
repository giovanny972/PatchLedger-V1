import sys, json, time, requests

def check_urls(urls):
    results = []
    for url in urls:
        t0 = time.time()
        r = requests.get(url, timeout=15)
        dt = time.time() - t0
        results.append({"url": url, "status": r.status_code, "ms": int(dt*1000)})
    return results

if __name__ == "__main__":
    urls = sys.argv[1:] or ["http://localhost/"]
    print(json.dumps(check_urls(urls), indent=2))
