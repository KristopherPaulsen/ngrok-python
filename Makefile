# system python interpreter. used only to create virtual environment
PY = python3
VENV = .env
BIN=$(VENV)/bin

# make it work on windows too
ifeq ($(OS), Windows_NT)
	BIN=$(VENV)/Scripts
	PY=python
endif

all: venv run

venv:
	: # Create venv if it doesn't exist
	test -d $(VENV) || ($(PY) -m venv $(VENV) && $(BIN)/pip install -r requirements.txt)

install:
	. $(BIN)/activate && pip install -r requirements.txt

examples-install:
	. $(BIN)/activate && pip install -r examples/requirements.txt

develop: venv
	. $(BIN)/activate && maturin develop

build: venv
	. $(BIN)/activate && maturin build

run: develop
	. $(BIN)/activate && ./examples/ngrok-http-minimal.py

run-aio: develop examples-install
	. $(BIN)/activate && python ./examples/aiohttp-ngrok.py

run-django: develop examples-install
	. $(BIN)/activate && python ./examples/django-single-file.py

# Run django using the manage.py which is auto-generated by "django-admin startproject"
# The manage.py file has the ngrok tunnel setup code.
run-djangosite: develop examples-install
	. $(BIN)/activate && python ./examples/djangosite/manage.py runserver localhost:1234

# Run django ASGI via uvicorn. The ngrok-asgi.py file has the ngrok tunnel setup code.
run-django-uvicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m uvicorn djangosite.ngrok-asgi:application

# Run django ASGI via gunicorn. The ngrok-asgi.py file has the ngrok tunnel setup code.
run-django-gunicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m gunicorn djangosite.ngrok-asgi:application -k uvicorn.workers.UvicornWorker

# Run ngrok ASGI via uvicorn. The python/ngrok/__main__.py file has the ngrok tunnel setup code.
run-ngrok-uvicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m ngrok uvicorn djangosite.asgi:application $(args)

# Run ngrok ASGI via gunicorn. The python/ngrok/__main__.py file has the ngrok tunnel setup code.
run-ngrok-gunicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m ngrok gunicorn djangosite.asgi:application -k uvicorn.workers.UvicornWorker $(args)

# Run ngrok-asgi script via uvicorn. The python/ngrok/__main__.py file has the ngrok tunnel setup code.
run-ngrok-asgi: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && ngrok-asgi uvicorn djangosite.asgi:application $(args)

run-flask: develop examples-install
	. $(BIN)/activate && python ./examples/flask-ngrok.py

run-full: develop
	. $(BIN)/activate && ./examples/ngrok-http-full.py

run-labeled: develop
	. $(BIN)/activate && ./examples/ngrok-labeled.py

run-tcp: develop
	. $(BIN)/activate && ./examples/ngrok-tcp.py

run-tls: develop
	. $(BIN)/activate && ./examples/ngrok-tls.py

run-uvicorn: develop examples-install
	. $(BIN)/activate && python ./examples/uvicorn-ngrok.py

# e.g.: make test='-k TestNgrok.test_gzip_tunnel' test
test: develop
	. $(BIN)/activate && python -m unittest discover test $(test)

# testfast is called by github workflow in ci.yml
testfast: develop
	. $(BIN)/activate && py.test -n 4 ./test/test*.py

testpublish:
	. $(BIN)/activate && maturin publish --repository testpypi

docs: develop black
	. $(BIN)/activate && sphinx-build -b html doc_source/ docs/

black: develop
	. $(BIN)/activate && black examples/ test/ python/

clean:
	rm -rf $(VENV) target/