# EVAL-10 — teste flaky

Lê integralmente as instruções e o prompt Playwright ou de testes correspondente à candidata.

A candidata contém uma condição de flakiness semeada. Deteta-a através de repetição controlada, identifica a causa e corrige-a deterministicamente. Não uses sleeps arbitrários, retries ilimitados, `skip`, ordem global, thresholds relaxados ou mocks que eliminem o comportamento. Repete o teste isolado e a suite afetada. Não faças commit.
