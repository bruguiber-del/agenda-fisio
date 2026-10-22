"""Genera index.html a partir de app.html y config.json.

config.json: {"supabaseUrl": "https://xxxx.supabase.co", "supabaseAnonKey": "eyJ..."}
La clave "anon"/"publishable" de Supabase es pública por diseño: solo permite llamar a las
funciones de schema.sql, que únicamente guardan y devuelven datos ya cifrados.
"""
import json, os, sys

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, "app.html"), encoding="utf-8").read()
cfg_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "config.json")
cfg = json.load(open(cfg_path)) if os.path.exists(cfg_path) else {}
url = cfg.get("supabaseUrl", "").rstrip("/")
key = cfg.get("supabaseAnonKey", "")
if url and key:
    src = src.replace("__SUPABASE_URL__", url).replace("__SUPABASE_ANON_KEY__", key)
connect = url or "'none'"
head = f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#1a73e8">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Agenda Fisio">
<!-- La página solo puede conectarse a su servidor de sincronización, y solo le envía datos cifrados. -->
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; connect-src {connect}; form-action 'none'; base-uri 'none'">
<meta name="referrer" content="no-referrer">
<meta name="robots" content="noindex, nofollow">
</head>
<body>
"""
out = os.path.join(here, "..", "index.html") if len(sys.argv) < 3 else sys.argv[2]
open(out, "w", encoding="utf-8").write(head + src + "\n</body>\n</html>\n")
print("escrito", out, "| servidor:", url or "(ninguno, solo local)")
