const translations = {
  en: {
    features: "Features",
    howItWorks: "How It Works",
    pricing: "Free & Open Source",
    faq: "FAQ",
    download: "View source",
    onDevice: "100% On-Device — No Cloud",
    heroTitle: "Organize Mac files automatically.",
    heroSubtitle: "On your schedule.",
    heroDesc: "iOrganize watches selected folders and applies your rules while the app is running — move, rename, archive, or clean up files on schedules you choose.",
    downloadFree: "View source and build",
    seeHow: "See How It Works",
    manualClicks: "Custom Rules",
    offline: "Offline",
    running: "On your Mac",
    stopDragging: "Stop dragging files by hand.",
    everythingYouNeed: "Everything you need to automate.",
    autoFlow: "Auto-Flow rules",
    autoFlowDesc: "Combine conditions such as file type, age, size, or name, then choose an action: move, rename, archive, send to Trash, or run a script. Rules run while iOrganize is open, immediately or on an hourly or daily schedule.",
    smartSanitize: "Smart Sanitize",
    smartSanitizeDesc: "One-tap scan for junk piling up on your Mac — old downloads, duplicate screenshots, forgotten installers. See exactly what's about to go before it's gone. Nothing deletes without your say.",
    onDeviceTitle: "Runs 100% on-device",
    onDeviceDesc: "No cloud, no account, no upload. iOrganize watches your folders locally and never sends a single file anywhere. Your Downloads folder stays exactly as private as it always was.",
    dailyWipe: "Scheduled screenshot cleanup",
    dailyWipeDesc: "Create a scheduled rule for old screenshots or other files. When iOrganize is running, it applies the cleanup on the schedule you choose.",
    threeSteps: "Three steps. Zero maintenance.",
    pickFolder: "Pick a folder & condition",
    pickFolderDesc: "Choose a folder inside your home directory. Set a condition — \"File type is .dmg\", \"Older than 30 days\", \"Is a screenshot\" — combine several with AND/OR.",
    chooseAction: "Choose what happens",
    chooseActionDesc: "Move to a folder, rename with a pattern, archive to zip, move to Trash, delete permanently, open with an app, or run a custom script.",
    setForget: "Set it and forget it",
    setForgetDesc: "Rules run while iOrganize is open, either immediately or on an hourly or daily schedule. Recent Activity records what happened.",
    workOffline: "Works offline",
    workOfflineDesc: "your files never leave your Mac",
    noCloud: "No cloud accounts.",
    noCloudDesc: "Built-in file processing stays on your Mac.",
    realAuto: "Real automation.",
    realAutoDesc: "Not a reminder to clean up — it just does it.",
    oneTimePurchase: "Every feature. Free.",
    pricing799: "Free and open source. No paid tiers or license keys.",
    free: "Free",
    smartSanitizeScan: "Smart Sanitize scans",
    moveRename: "Move, rename, trash actions",
    scheduledRuns: "Scheduled runs",
    scriptActions: "Script actions",
    unlimitedRules: "Unlimited rules",
    unlimited: "Unlimited rules",
    scheduledRunsDesc: "Scheduled runs — hourly or daily",
    runScript: "Run script actions",
    openWith: "Open with app actions",
    fullHistory: "Full activity history",
    downloadBtn: "View source and build",
    ready: "Ready to stop cleaning up by hand?",
    readyDesc: "Explore the free source and build instructions. No account or license required.",
    noCard: "No account. No license key.",
    questions: "Questions?",
    contact: "We're here to help.",
    faqTitle: "Frequently Asked Questions",
    gotQuestions: "Got questions? We've got answers.",
    isItFree: "Is it really free?",
    isFreeAnswer: "Yes. iOrganize is free and open source. All Auto-Flow rules, scheduled runs, Smart Sanitize scans, and actions are available without an account or license.",
    whatMac: "What Mac do I need?",
    macAnswer: "Any Mac with Apple Silicon (M1, M2, M3, or M4) running macOS 14 (Sonoma) or later.",
    willDelete: "Will it delete my files without asking?",
    deleteAnswer: "Smart Sanitize previews candidates, starts every category unselected, and asks for confirmation. Some cache and log categories delete permanently; others move to Trash. Enabled Auto-Flow rules can act automatically, including permanent deletion if you choose it.",
    icloud: "Does it work with iCloud Drive?",
    icloudAnswer: "Rules watch local folders inside your home directory. iCloud-synced folders may work when their local path and macOS permissions permit it; test with a disposable file first.",
    isPrivate: "Is my data really private?",
    privateAnswer: "Absolutely. iOrganize runs entirely on your Mac. Nothing is uploaded, no account is required, and we don't collect telemetry or track anything. Your activity log stays local to your machine.",
    productLink: "Product",
    supportLink: "Support",
    alsoInSuite: "Also in iSuite",
    ivoz: "iVoz — Voice dictation",
    screenBridge: "Screen Bridge — Mac connectivity",
    ibrain: "iBrain — Local AI assistant",
    istats: "iStats — System monitoring",
    thanks: "Thanks for using iOrganize.",
    contactInfo: "Free and open source"
  },
  es: {
    features: "Características",
    howItWorks: "Cómo funciona",
    pricing: "Gratis y código abierto",
    faq: "Preguntas frecuentes",
    download: "Ver código",
    onDevice: "100% En el dispositivo — Sin nube",
    heroTitle: "Organiza tus archivos en Mac automáticamente.",
    heroSubtitle: "Según tu horario.",
    heroDesc: "iOrganize vigila las carpetas que eliges y aplica tus reglas mientras la app está abierta: mover, renombrar, archivar u organizar archivos según el horario que configures.",
    downloadFree: "Ver código y compilar",
    seeHow: "Ver cómo funciona",
    manualClicks: "Reglas personalizadas",
    offline: "Sin conexión",
    running: "En tu Mac",
    stopDragging: "Deja de arrastrar archivos manualmente.",
    everythingYouNeed: "Todo lo que necesitas para automatizar.",
    autoFlow: "Reglas de flujo automático",
    autoFlowDesc: "Si coincide, sucede. Combina condiciones — tipo de archivo, edad, tamaño, nombre, captura de pantalla — con AND/OR, luego elige una acción: mover, renombrar, archivar, eliminar o ejecutar un script. Se ejecuta inmediatamente, cada hora o diariamente. Sin clics nunca.",
    smartSanitize: "Smart Sanitize",
    smartSanitizeDesc: "Escanea en un toque los archivos innecesarios en tu Mac — descargas antiguas, capturas de pantalla duplicadas, instaladores olvidados. Ve exactamente qué está a punto de eliminarse antes de que desaparezca. Nada se elimina sin tu consentimiento.",
    onDeviceTitle: "Se ejecuta 100% en el dispositivo",
    onDeviceDesc: "Sin nube, sin cuenta, sin carga. iOrganize vigila tus carpetas localmente y nunca envía un solo archivo a ningún lado. Tu carpeta Descargas sigue siendo exactamente tan privada como siempre.",
    dailyWipe: "Limpieza programada de capturas",
    dailyWipeDesc: "Crea una regla programada para capturas de pantalla antiguas u otros archivos. Cuando iOrganize está abierto, aplica la limpieza según el horario que elijas.",
    threeSteps: "Tres pasos. Cero mantenimiento.",
    pickFolder: "Elige una carpeta y condición",
    pickFolderDesc: "Apunta una regla a Descargas, Escritorio o cualquier lugar. Establece una condición — \"El tipo de archivo es .dmg\", \"Anterior a 30 días\", \"Es una captura de pantalla\" — combina varias con AND/OR.",
    chooseAction: "Elige qué sucede",
    chooseActionDesc: "Mover a una carpeta, renombrar con un patrón, archivar en zip, mover a Papelera, eliminar permanentemente, abrir con una aplicación o ejecutar un script personalizado.",
    setForget: "Configúralo y olvídalo",
    setForgetDesc: "Las reglas se ejecutan mientras iOrganize está abierto, inmediatamente o con un horario por hora o diario. El historial registra lo que sucedió.",
    workOffline: "Funciona sin conexión",
    workOfflineDesc: "tus archivos nunca abandonan tu Mac",
    noCloud: "Sin cuentas en la nube.",
    noCloudDesc: "Ningún dato sale de tu carpeta Descargas.",
    realAuto: "Automatización real.",
    realAutoDesc: "No es un recordatorio para limpiar — simplemente lo hace.",
    oneTimePurchase: "Todas las funciones. Gratis.",
    pricing799: "Gratis y código abierto. Sin niveles pagos ni licencias.",
    free: "Gratis",
    smartSanitizeScan: "Escaneos Smart Sanitize",
    moveRename: "Acciones de mover, renombrar, eliminar",
    scheduledRuns: "Ejecuciones programadas",
    scriptActions: "Acciones de script",
    unlimitedRules: "Reglas ilimitadas",
    unlimited: "Reglas ilimitadas",
    scheduledRunsDesc: "Ejecuciones programadas — cada hora o diariamente",
    runScript: "Ejecutar acciones de script",
    openWith: "Acciones abrir con",
    fullHistory: "Historial de actividades completo",
    downloadBtn: "Ver código y compilar",
    ready: "¿Listo para dejar de limpiar a mano?",
    readyDesc: "Consulta el código y las instrucciones de compilación gratis. No requiere cuenta ni licencia.",
    noCard: "Sin cuenta ni licencia.",
    questions: "¿Preguntas?",
    contact: "Estamos aquí para ayudarte.",
    faqTitle: "Preguntas frecuentes",
    gotQuestions: "¿Tienes preguntas? Tenemos respuestas.",
    isItFree: "¿Es realmente gratis?",
    isFreeAnswer: "Sí. iOrganize es gratis y de código abierto. Todas las reglas Auto-Flow, ejecuciones programadas, análisis Smart Sanitize y acciones están disponibles sin cuenta ni licencia.",
    whatMac: "¿Qué Mac necesito?",
    macAnswer: "Cualquier Mac con Apple Silicon (M1, M2, M3 o M4) ejecutando macOS 14 (Sonoma) o posterior.",
    willDelete: "¿Eliminará mis archivos sin preguntar?",
    deleteAnswer: "Smart Sanitize muestra los archivos candidatos, inicia todas las categorías desactivadas y pide confirmación. Algunas categorías de cachés y registros borran permanentemente; otras mueven a la Papelera. Las reglas activadas pueden actuar automáticamente, incluso borrar permanentemente si lo eliges.",
    icloud: "¿Funciona con iCloud Drive?",
    icloudAnswer: "Las reglas vigilan carpetas locales dentro de tu carpeta de usuario. Las carpetas de iCloud pueden funcionar si su ruta local y los permisos de macOS lo permiten; prueba primero con un archivo temporal.",
    isPrivate: "¿Mis datos son realmente privados?",
    privateAnswer: "Absolutamente. iOrganize se ejecuta completamente en tu Mac. Nada se carga, no se requiere cuenta y no recopilamos telemetría ni rastreamos nada. Tu registro de actividades permanece local en tu máquina.",
    productLink: "Producto",
    supportLink: "Soporte",
    alsoInSuite: "También en iSuite",
    ivoz: "iVoz — Dictado de voz",
    screenBridge: "Screen Bridge — Conectividad para Mac",
    ibrain: "iBrain — Asistente de IA local",
    istats: "iStats — Monitoreo del sistema",
    thanks: "Gracias por usar iOrganize.",
    contactInfo: "Gratis y código abierto"
  }
};

function setLanguage(lang) {
  localStorage.setItem('ioLanguage', lang);
  document.documentElement.lang = lang;
  document.body.setAttribute('data-language', lang);
  updatePageText(lang);
}

function getLanguage() {
  return localStorage.getItem('ioLanguage') || 'en';
}

function updatePageText(lang) {
  const t = translations[lang];

  // Update text elements
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (t[key]) {
      if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
        el.placeholder = t[key];
      } else {
        // For elements with br tags or other HTML, use innerHTML
        // For simple text, use textContent to avoid XSS
        const text = t[key];
        if (text.includes('<br') || text.includes('&br;')) {
          el.innerHTML = text;
        } else if (el.childNodes.length === 0 || (el.childNodes.length === 1 && el.childNodes[0].nodeType === 3)) {
          // Simple text node
          el.textContent = text;
        } else {
          // Has other elements (like spans), update textContent of direct text only
          el.textContent = text;
        }
      }
    }
  });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
  const currentLang = getLanguage();
  setLanguage(currentLang);
});
