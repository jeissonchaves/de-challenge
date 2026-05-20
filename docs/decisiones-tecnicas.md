# Decisiones Técnicas — Analytics Layer

> **Proyecto:** meetup_dbt / Snowflake  
> **Capa:** Analytics (Dimensiones · Facts · Marts)  
> **Fecha:** 2026-05-20  
> **Autor:** Jchaves

---

## 1. Granularidad de `fact_attendance`

**Decisión:** Una fila por evento (no por miembro × evento).

**Contexto:** El modelo solicitado inicialmente incluía `member_id`, `attended`, `guests` y
`response_time` en la fact table, lo que implica una tabla de RSVPs individuales
(un registro por miembro que responde a un evento). Esta tabla no existe en el
dataset raw disponible.

---

## 2. Dimensión `dim_date` generada sintéticamente

**Decisión:** Generar la dimensión de tiempo con `GENERATOR` de Snowflake.

**Convención de clave:** `DATE_KEY` en formato `YYYYMMDD` (INT) para joins eficientes
sin necesidad de conversión de tipos en tiempo de query.

---

## 3. Ciudad del evento: venue vs grupo

**Decisión:** En los marts geográficos, la ciudad se resuelve con:
```sql
coalesce(f.VENUE_CITY, g.CITY) as CITY
```

**Razonamiento:**
- `VENUE_CITY` es la ubicación real del evento → más precisa.
- Si el venue no tiene ciudad (eventos online o sin venue), se usa la ciudad
  del grupo como fallback razonable.

---

## 4. Materialización `table` para analytics

**Decisión:** Toda la capa analytics se materializa como `table` (no `view` ni `incremental`).

**Razonamiento:**
- Los marts tienen JOINs y window functions complejas → materializar evita
  recalcular en cada query de BI.
- El volumen de datos (Meetup histórico) cabe en tablas estáticas sin necesidad
  de estrategia incremental.
- Las dimensiones son relativamente pequeñas y estables.

---

## 5. Pendientes, oportunidad de mejora
### Oportunidad 1
**Modelado Histórico:** Las dimensiones `dim_member` y `dim_member` se reescriben no guardan historico (SCD tipon1)

**Mejora:**
- Usar dbt snapshots para poder tener SCD tipo 2. 
### Oportunidad 2
**Incremental en analitica:** Actualmente las tablas de la capa analitica se materializan con full refresh, 

**Mejora:**
- Cambiar la materializacion a incrfemental usando un mAX(date) para reducir el procesamiento.

### Oportunidad 3
**Pruebas de calidad:** Se agregaron tests basicos con dbt que cubren limpieza de nulls, casteo... 

**Mejora:**
- Se pueden incluir testa mas avanzados como de integridad referencial. 
