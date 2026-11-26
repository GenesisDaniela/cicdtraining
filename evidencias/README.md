# Evidencias de la práctica

## 1. Pipeline y despliegue
- [Ejecuciones en GitHub Actions](https://github.com/GenesisDaniela/cicdtraining/actions)

Respuesta de la app en Cloud Run:

![App en línea](app-en-linea.png)

## 2. Prueba de carga con k6
- [Resumen de la prueba](k6-resultado.txt)

## 3. Alertas

Alertas de latencia y de tasa de errores disparadas durante la prueba:

![Alertas disparadas](alertas-disparadas.png)

Alerta de disponibilidad. Se abrió cuando casi no había tráfico, porque mide peticiones por segundo y no un porcentaje:

![Alerta de disponibilidad](alerta-disponibilidad.png)

## 4. Registros

Errores 500 generados a propósito por k6:

![Registros con errores 500](logs-errores-k6.png)

## 5. Integración con Gemini
- [Análisis de los resultados](analisis-gemini.md)

## 6. Notificaciones por correo

Avisos recibidos:

![Avisos recibidos](correo-bandeja.png)

Latencia alta:

![Latencia alta](correo-latencia.png)

Tasa de errores 5xx:

![Tasa de errores 5xx](correo-errores.png)

Tasa de errores recuperada:

![Tasa de errores recuperada](correo-errores-recuperada.png)

Disponibilidad (con casi nada de tráfico, valor 0):

![Disponibilidad (con casi nada de tráfico, valor 0)](correo-disponibilidad.png)

Disponibilidad recuperada:

![Disponibilidad recuperada](correo-disponibilidad-recuperada.png)
