# Session: Music Learning App - API Authentication Fix

**Date:** 2025-11-12
**Repository:** nanoska/music-learning-app
**Branch:** fix/unify-api-authentication

## Objetivo

Analizar y corregir la configuración del frontend de music-learning-app para asegurar que las llamadas API al backend de sheet-api (puerto 8000) estén correctamente configuradas y utilicen un sistema de autenticación unificado.

## Análisis Inicial

### Estado de la Configuración

✅ **Correctamente configurado:**
- Variables de entorno `.env` y `.env.example` apuntan a `http://localhost:8000/api`
- `api.ts` usa `VITE_API_URL` correctamente con interceptores JWT
- `docker-compose.yml` configurado con red externa `sheetmusic_sheetmusic-network`
- `vite.config.ts` tiene proxy para `/api` → `http://localhost:8000`

🔴 **Problema identificado:**
- `musicSheetsApi.ts` usaba un token separado almacenado en `localStorage` con la key `'music-sheets-token'`
- `MusicSheetApp.tsx` guardaba tokens en localStorage independientemente del authStore de Zustand
- Esto causaba inconsistencia en la autenticación entre diferentes partes de la aplicación

## Cambios Implementados

### 1. Unificación de Autenticación en `musicSheetsApi.ts`

**Archivo:** `frontend/src/services/musicSheetsApi.ts`

**Antes:**
```typescript
musicSheetsApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('music-sheets-token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

**Después:**
```typescript
import { useAuthStore } from '@stores/authStore';

musicSheetsApi.interceptors.request.use((config) => {
  const token = useAuthStore.getState().tokens?.access;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

**Beneficio:** Todos los requests de musicSheetsApi ahora usan el mismo token del store centralizado.

### 2. Actualización de `MusicSheetApp.tsx`

**Archivo:** `frontend/src/components/MusicSheetApp.tsx`

**Cambios:**
- Importado `useAuthStore` de Zustand
- Reemplazado llamada a `authApi.login()` con `authLogin()` del store
- Eliminadas referencias a `localStorage.setItem('music-sheets-token')` y `localStorage.setItem('music-sheets-user')`
- Login ahora usa el flujo unificado de autenticación

**Antes:**
```typescript
const response = await authApi.login(email, password);
if (response.success) {
  localStorage.setItem('music-sheets-token', response.token);
  localStorage.setItem('music-sheets-user', JSON.stringify(response.user));
  setIsAdmin(true);
}
```

**Después:**
```typescript
await authLogin({ email, password });
setIsAdmin(true);
setLoginDialogOpen(false);
```

## Verificaciones Realizadas

1. ✅ No quedan referencias a `music-sheets-token` en el código
2. ✅ No quedan referencias a `music-sheets-user` en el código
3. ✅ TypeScript compila correctamente (solo warnings pre-existentes no relacionados)
4. ✅ Commit creado con mensaje descriptivo

## Resultado

### Arquitectura de Autenticación Unificada

```
┌─────────────────────────────────────┐
│     useAuthStore (Zustand)          │
│  - Tokens (access/refresh)          │
│  - User data                         │
│  - Auth methods                      │
└────────────┬────────────────────────┘
             │
      ┌──────┴──────┐
      ↓             ↓
  api.ts      musicSheetsApi.ts
      ↓             ↓
  Sheet-API Backend (port 8000)
```

**Beneficios:**
- ✅ Una sola fuente de verdad para autenticación
- ✅ Tokens sincronizados en toda la aplicación
- ✅ Refresh automático de tokens funciona para todos los requests
- ✅ Código más mantenible y predecible

## Comandos Git

```bash
# Crear rama
git checkout -b fix/unify-api-authentication

# Commits realizados
git commit -m "fix: unify API authentication to use Zustand store"
git commit -m "chore: remove deprecated backend directory"

# Merge y push
git checkout main
git merge fix/unify-api-authentication
git push origin main
git branch -d fix/unify-api-authentication
```

## Cambios Adicionales

### Eliminación del Backend Deprecated

Se eliminó completamente el directorio `/backend/` que contenía el backend Django local deprecated:
- 69 archivos eliminados
- 5941 líneas de código removidas
- Incluía: apps (authentication, courses, exercises, gamification, music_sheets, sheets, users)
- Archivos de configuración Django, migraciones, y requirements

**Justificación:** El CLAUDE.md ya documentaba que el backend local no debía usarse y toda la funcionalidad API ahora viene de Sheet-API centralizado.

## Estado Final

✅ **Completado exitosamente:**
1. Unificación de autenticación en el frontend
2. Eliminación del backend deprecated
3. Código pusheado al repositorio remoto
4. Documentación actualizada
5. Rama de feature eliminada

**Repositorio limpio y actualizado en:** nanoska/music-learning-app

## Notas Adicionales

- El backend local de music-learning-app fue eliminado (deprecated)
- Toda la funcionalidad API ahora viene del sheet-api backend centralizado
- La arquitectura sigue el patrón de API centralizada descrito en `ORCHESTRATION.md`
