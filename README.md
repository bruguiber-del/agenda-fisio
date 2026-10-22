# Agenda Fisio

Agenda tipo Google Calendar y fichas de pacientes con historial clínico para una consulta de
fisioterapia. Se entra **solo con una contraseña**, sin correo ni cuenta, y se ve lo mismo en
el móvil y en el ordenador.

## Privacidad

- Todo se **cifra en el propio móvil u ordenador** antes de salir, con AES-GCM de 256 bits.
  La clave se obtiene de la contraseña con PBKDF2-SHA256 (600.000 iteraciones) más HKDF.
- El servidor (Supabase) solo guarda **texto cifrado**. Nunca recibe la contraseña, la clave,
  los nombres ni los datos clínicos. Quien tenga acceso al servidor solo ve datos ilegibles.
- El identificador de la agenda en el servidor y el permiso para modificarla también se
  obtienen de la contraseña. Sin ella no se puede ni encontrar ni sobrescribir la agenda.
- La página solo puede conectarse a su servidor. Lo impone la política de seguridad de la página.
- Se guarda una copia cifrada en cada dispositivo, así que la agenda abre aunque no haya conexión.
  Los cambios se sincronizan cuando vuelve la conexión.
- ⚠ **La contraseña no se puede recuperar.** Si se olvida, los datos no se pueden abrir.
  Conviene descargar de vez en cuando una copia cifrada (Ajustes → Descargar copia cifrada).

## Puesta en marcha (una sola vez)

### 1. Base de datos (Supabase, gratis)
1. Crea un proyecto en https://supabase.com. Elige la región de Europa.
2. Ve a **SQL Editor**, pega el contenido de [`supabase/migrations/20261022000000_agenda_cifrada.sql`](supabase/migrations/20261022000000_agenda_cifrada.sql) y pulsa **Run**.
3. En **Project Settings → API** (o **Data API**), copia la **Project URL** y la clave pública
   **anon / publishable**. No uses nunca la clave `service_role` ni la `secret`.
4. Crea `web/config.json`:
   ```json
   { "supabaseUrl": "https://TU-PROYECTO.supabase.co", "supabaseAnonKey": "TU-CLAVE-ANON" }
   ```
   y ejecuta `python3 web/build.py`, que genera `index.html`.

### 2. Publicar la página (GitHub Pages, gratis)
En el repositorio de GitHub: **Settings → Pages → Source: Deploy from a branch → `main` / `(root)`**.
En un minuto la agenda queda en `https://USUARIO.github.io/agenda-fisio/`.

### 3. Usarla
- Abre la dirección en el móvil y en el ordenador.
- La primera vez, escribe la contraseña que quieras usar y pulsa **Entrar**. Te pide repetirla
  para crear la agenda.
- En el iPhone, en Safari → Compartir → **Añadir a pantalla de inicio**, queda como una app.

## Funciones

- **Calendario:** vistas de día, semana y mes, citas repetidas cada semana, tipos con colores
  y estados (programada, realizada, no asistió, cancelada).
- **Pacientes:** ficha completa (contacto, DNI, diagnóstico, antecedentes, alergias, consentimiento RGPD)
  e historial por sesiones (subjetivo, exploración, tratamiento, ejercicios, dolor EVA, evolución).
  Incluye buscador, próximas citas e impresión del historial.
- **Sincronización:** si se cambian cosas distintas en el móvil y en el ordenador a la vez,
  se conservan las dos.
- **Seguridad:** bloqueo automático por inactividad, cambio de contraseña, copias cifradas
  descargables y restauración de copias.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La app ya generada, que es lo que se publica |
| `web/app.html` | El código fuente de la app |
| `web/build.py` | Genera `index.html` con los datos del servidor |
| `supabase/migrations/` | La base de datos, que solo guarda agendas cifradas |

## Nota legal (RGPD)

Los datos de salud son datos de categoría especial. El cifrado de extremo a extremo ayuda mucho,
pero no cubre todas las obligaciones. Siguen siendo necesarios el consentimiento informado del
paciente, el registro de actividades de tratamiento, el contrato de encargado de tratamiento
con Supabase (su DPA) y la conservación de la historia clínica durante el plazo legal.
Consulta con tu colegio profesional.
