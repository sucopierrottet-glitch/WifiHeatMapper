# 🚀 Guía Maestra de Publicación en Tiendas: WiFi HeatMapper Pro (Google Play & Apple App Store)

Esta guía detalla los pasos exactos, configuraciones y recursos para compilar y publicar **WiFi HeatMapper Pro** (`com.simpleappspg.wifiheatmapper`) bajo el modelo **Camino 1: Paid App (100% Pro Unlocked, sin anuncios ni paywalls)**.

---

## 📦 1. Recursos Generados en el Repositorio

| Recurso | Ubicación | Descripción |
| :--- | :--- | :--- |
| **Android Keystore de Producción** | `android/app/upload-keystore.jks` | Llave criptográfica RSA 2048-bit para firma de subida (Upload Key). |
| **Credenciales de Firma** | `android/key.properties` | Configuración de firma para Gradle release. |
| **Generador de Ícono 1024x1024** | `generate_icon.py` | Script Python (Pillow) que genera `assets/icon/app_icon.png`. |
| **Generador de Store Assets** | `generate_store_assets.py` | Genera `icon_512.png`, `feature_graphic_1024x500.png` y 4 capturas 1080x1920 en `store_assets/`. |
| **Política de Privacidad** | `privacy_policy.html` | Documento legal Offline-First para Google Play Console y App Store Connect. |

---

## 🤖 2. Configuración en Google Play Console

1. **Application ID:** `com.simpleappspg.wifiheatmapper`
2. **Modelo de Monetización:** Aplicación de Pago Único (Camino 1 — 100% Pro Desbloqueado desde el primer inicio, sin compras integradas ni bloqueos).
3. **Título:** `WiFi HeatMapper Pro: Plano & EMF`
4. **Descripción Corta (<= 80 caracteres):**
   > *Mapeo térmico Wi-Fi 2D por habitación, analizador de canales, FSPL y radar EMF.*
5. **Descripción Completa:**
   > *WiFi HeatMapper Pro es la herramienta de campo definitiva para ingenieros de telecomunicaciones, instaladores de redes inalámbricas y técnicos de TI.*
   > • **Lienzo Interactivo de Plano Térmico 2D:** Toca cada habitación para registrar niveles de señal en dBm y pintar el mapa de calor en tiempo real (Verde / Amarillo / Rojo).
   > • **Coordenadas Óptimas del Router:** Algoritmo de centroide ponderado que sugiere la ubicación ideal del punto de acceso evitando zonas de alta interferencia EMF.
   > • **Analizador de Espectro 2.4 GHz y 5 GHz:** Visualización de solapamiento co-canal y canal adyacente con recomendación de canales limpios (1, 6, 11 y UNII 36-165).
   > • **Calculadora FSPL (Free-Space Path Loss):** Estimación de distancia y atenuación en espacio libre e interiores.
   > • **Radar Magnetómetro EMF (µT) en Vivo:** Lectura directa del sensor magnético para detectar transformadores, motores o tableros eléctricos que degradan la señal RF.
   > • **Reportes Técnicos PDF Firmados:** Exportación A4 con tabla por habitación y firma digital del ingeniero.

---

## 🛠️ 3. Comandos de Verificación y Compilación

```bash
# Regenerar ícono y capturas de tienda
python generate_icon.py
python generate_store_assets.py
dart run flutter_launcher_icons

# Análisis estático y pruebas automatizadas
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test

# Compilar Android App Bundle (.aab) para Google Play
C:\flutter\bin\flutter.bat build appbundle --release
```
