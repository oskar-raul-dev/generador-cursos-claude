def pytest_addoption(parser):
    parser.addoption("--update-golden", action="store_true",
                     help="reescribe los .expected.json con la salida actual")
