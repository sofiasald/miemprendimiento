# App de Gestión para Emprendimiento

App de gestión con Flutter y SQLite.

## Manejo de Estado (Regla del Equipo)

**Provider elegido:** `provider`

**Reglas de uso:**
Todo dato que se muestra en más de una pantalla vive en un Provider, nunca en variables sueltas de una pantalla. 
⚠️ Cuidado: No usar `setState` local para guardar datos que se comparten para "ir más rápido", ya que ese dato se va a desincronizar del resto de la app.
