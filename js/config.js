// ============================================
// CONFIGURAÇÃO DO SUPABASE
// ============================================
// INSTRUÇÕES:
// 1. Crie um projeto em https://supabase.com
// 2. Copie a URL e a ANON KEY do seu projeto
// 3. Cole abaixo nos campos correspondentes
// ============================================

const SUPABASE_URL = 'https://gsbdimmbokkzhqkehenv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzYmRpbW1ib2tremhxa2VoZW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MzM3NDksImV4cCI6MjA4ODMwOTc0OX0.ejfgwZl1C6NsD0J2RhymVK6ajXNcG15khh8srpXGHs8';

// Configurações do sistema
const CONFIG = {
  // Tolerância de atraso em minutos
  TOLERANCIA_ATRASO_MIN: 10,

  // Tempo de validade do QR Code em minutos
  QR_VALIDADE_MIN: 5,

  // Raio padrão de geolocalização em metros
  RAIO_PADRAO_METROS: 50,

  // Precisão mínima do GPS em metros
  GPS_PRECISAO_MIN: 100,

  // Nome do app
  APP_NAME: 'Presença Digital',

  // Versão
  VERSION: '1.0.0',

  // URL base do site (para gerar QR codes)
  // Altere para a URL de produção após deploy
  BASE_URL: window.location.origin,

  // ID da planilha Google Sheets (para sincronização)
  GOOGLE_SHEET_ID: '',
};

// Inicializar Supabase Client
const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Exportar para uso global
window.supabaseClient = supabaseClient;
window.CONFIG = CONFIG;
