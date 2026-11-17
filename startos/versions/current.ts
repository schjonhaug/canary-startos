import { VersionInfo } from '@start9labs/start-sdk'

export const current = VersionInfo.of({
  version: '1.7.2:0',
  releaseNotes: {
    en_US: `This update contains bug fixes and security updates:
  - Fixed a rare race where a newly added wallet could be removed during background cleanup
  - Improved responsiveness by moving password hashing, wallet storage and Electrum reconnects off the main workers
  - Updated Next.js and backend dependencies to fix several security advisories`,
    es_ES: `Esta actualización incluye correcciones de errores y actualizaciones de seguridad:
  - Corregida una condición de carrera poco frecuente por la que una cartera recién añadida podía eliminarse durante la limpieza en segundo plano
  - Mejorada la capacidad de respuesta al sacar el hash de contraseñas, el almacenamiento de carteras y las reconexiones a Electrum de los procesos principales
  - Actualizados Next.js y las dependencias del backend para corregir varios avisos de seguridad`,
    de_DE: `Dieses Update enthält Fehlerbehebungen und Sicherheitsupdates:
  - Eine seltene Race Condition behoben, durch die eine neu hinzugefügte Wallet bei der Bereinigung im Hintergrund entfernt werden konnte
  - Reaktionsfähigkeit verbessert, indem Passwort-Hashing, Wallet-Speicherung und Electrum-Neuverbindungen aus den Haupt-Workern ausgelagert wurden
  - Next.js und Backend-Abhängigkeiten aktualisiert, um mehrere Sicherheitshinweise zu beheben`,
    pl_PL: `Ta aktualizacja zawiera poprawki błędów i aktualizacje bezpieczeństwa:
  - Naprawiono rzadki wyścig, w którym nowo dodany portfel mógł zostać usunięty podczas czyszczenia w tle
  - Poprawiono responsywność dzięki przeniesieniu haszowania haseł, zapisu portfeli i ponownych połączeń z Electrum poza główne wątki robocze
  - Zaktualizowano Next.js i zależności backendu, aby usunąć kilka luk bezpieczeństwa`,
    fr_FR: `Cette mise à jour contient des corrections de bugs et des mises à jour de sécurité :
  - Correction d'une situation de concurrence rare qui pouvait supprimer un portefeuille nouvellement ajouté lors du nettoyage en arrière-plan
  - Amélioration de la réactivité en déplaçant le hachage des mots de passe, le stockage des portefeuilles et les reconnexions Electrum hors des workers principaux
  - Mise à jour de Next.js et des dépendances du backend pour corriger plusieurs avis de sécurité`,
  },
  migrations: {},
})
