# ChargeGO

Aplicación móvil desarrollada con Flutter y Firebase como proyecto final.  
ChargeGO ofrece autenticación de usuarios, persistencia de datos, navegación moderna y soporte para modo claro y oscuro.

---

# Integrantes

- Nil Sanchez
- Karolina Klimina

---

# Tecnologías utilizadas

## Frontend
- Flutter
- Dart

## Backend / Base de Datos
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

## Otras herramientas
- Android Studio
- Git + GitHub

---

# Funcionalidades principales

- Login y registro de usuarios
- Persistencia de sesión
- Logout
- CRUD completo
- Perfil editable
- Búsqueda y filtros
- Navegación entre pantallas
- Tema claro y tema oscuro
- Validación de formularios
- Mensajes de error con SnackBar/Dialog
- Persistencia de datos con Firebase

---

# Arquitectura del proyecto

El proyecto está separado por capas:

## UI
Pantallas y widgets visuales.

## Lógica
Gestión de estado, servicios y funcionalidades.

## Datos
Conexión con Firebase y modelos de datos.

Esta estructura facilita el mantenimiento y evita una arquitectura monolítica.

---

# Estructura de pantallas

- Login
- Registro
- Home
- Perfil
- Configuración
- Crear/Editar contenido

---

# Firebase

Firebase se utiliza para:

- Autenticación de usuarios
- Persistencia de datos
- Almacenamiento de información
- Gestión de colecciones

---

# Seguridad

La aplicación utiliza reglas de Firebase para proteger los datos.

Solo los usuarios autenticados pueden acceder a determinadas funcionalidades y datos.

---

# Accesibilidad

- Texto escalable
- Botones accesibles
- Contraste adecuado
- Navegación intuitiva

---

# Tema claro y oscuro

La aplicación incorpora:

- Light Theme
- Dark Theme

Ambos temas mantienen coherencia visual y accesibilidad.

# chargego

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
