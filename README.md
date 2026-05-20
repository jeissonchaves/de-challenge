# Meetup Analytics - Data Engineering Challenge

Este proyecto implementa un pipeline de datos de extremo a extremo utilizando **Apache Airflow**, **dbt** y **Snowflake**. El objetivo es ingestar datos de la plataforma Meetup desde GCS, transformarlos para su análisis (capas Raw, Staging y Analytics) y exportarlos desde snowflake a GCS.

## Arquitectura y DAGs
- **`csv_to_snowflake_ingestion`**: Realiza la ingesta en capas (Tiers) desde archivos en Google Cloud Storage hacia Snowflake (esquema `RAW`).
- **`dbt_transformations`**: Ejecuta todos los modelos de dbt usando `astronomer-cosmos`. Construye el DAG de dbt automáticamente infiriendo el orden: primero la capa de Staging, luego Dimensiones, Facts y finalmente Marts analíticos.
- **`snowflake_to_gcs`**: Exporta los resultados transformados desde Snowflake hacia GCS.

Las dependencias entre DAGs son manejadas nativamente por **Assets de Airflow**. Cuando un DAG termina, actualiza su Asset y dispara automáticamente el siguiente en la cadena.
Se envia una notificacion a slack cuando un DAG termina ya sea exitoso o fallido con el link al log del error. 

---

## 🚀 Guía de Inicio Rápido: Levantar y Probar el Ambiente

### 1. Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:
1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o el motor de Docker corriendo).
2. [Astro CLI](https://docs.astronomer.io/astro/cli/install-cli) (La herramienta oficial de Astronomer para correr Airflow localmente).
3. Una cuenta de **Snowflake** (tus credenciales se usarán más adelante).

### 2. Clonar el repositorio
```bash
git clone https://github.com/jeissonchaves/de-challenge.git
cd de-challenge
```

### 3. Configurar Credenciales (`airflow_settings.yaml`)
las credenciales se usan desde airflow connections y variables, para prueba desde local se cargan en el archivo `airflow_settings.yaml`.

Agrega tu archivo `airflow_settings.yaml` en la raíz del proyecto (junto a este README).
Puedes usar el archivo de plantilla proporcionado como punto de partida:
```bash
cp airflow_settings.example.yaml airflow_settings.yaml
```

Debe incluir:
- La conexión a Snowflake con el ID `snowflake_default` (usada tanto por las funciones en Python como por dbt-cosmos).
- La conexión de Slack (opcional para alertas).
- La Variable `job_config`, que define las capas de ingesta (Tiers).

*(Nota: `airflow_settings.yaml` es ignorado por git por seguridad. Si no lo tienes, deberás rellenar la plantilla con tus credenciales).*

### 4. Levantar el ambiente local
Con el Astro CLI instalado, descarga las imágenes de Docker, instala las librerías necesarias (`dbt-snowflake`, `astronomer-cosmos`, etc. desde `requirements.txt`) e inicia Airflow ejecutando:

```bash
astro dev start
```

### 5. Acceder a Airflow
1. Cuando la terminal indique que los contenedores están listos, abre tu navegador web en [http://localhost:8080](http://localhost:8080).
2. Ingresa con las credenciales por defecto:
   - **Usuario**: `admin`
   - **Contraseña**: `admin`

### 6. Ejecutar y Probar el Pipeline
1. En la pantalla principal verás los 3 DAGs. 
2. **Habilita** los 3 DAGs haciendo clic en el switch azul a la izquierda del nombre de cada uno.
3. Haz clic en el botón de **Play (Trigger DAG)** del DAG `csv_to_snowflake_ingestion`.
4. **¡Monitorea la ejecucion!**
   - Una vez termine la ingesta, verás que la pestaña "Datasets / Assets" registra el evento y esto disparará automáticamente el DAG `dbt_transformations`.
   - Finalmente, al terminar las transformaciones, se disparará `snowflake_to_gcs`.

---

## 📊 Capa de Analytics (Marts)
Los modelos analíticos construidos sobre las fuentes crudas se encuentran en `dbt/models/analytics/`. Estos incluyen dimensiones (`dim_date`, `dim_member`, `dim_group`), hechos (`fact_attendance`) y data marts.

> **Para más detalles sobre el diseño de la capa analítica y las suposiciones del modelo de datos, consulta la documentación técnica en `docs/decisiones-tecnicas.md`.**
