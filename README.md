# 📋 Presença Digital

Sistema web de marcação de presença de alunos com **QR Code dinâmico** e **validação de geolocalização**.

## 🚀 Funcionalidades

### Para o Aluno
- Login/Cadastro por matrícula
- Visualização das aulas do dia
- Marcar presença via **QR Code** (câmera do celular) ou manualmente
- Validação de **geolocalização** (GPS) — precisa estar na sala
- **Tolerância de 10 minutos** — após isso, presença é registrada como "Atrasado (X min)"
- Histórico completo de presenças com filtros e estatísticas

### Para o Professor
- Dashboard com estatísticas do dia
- CRUD de **Disciplinas** e **Turmas** (dia, horário, sala, GPS)
- Vinculação de alunos às turmas por matrícula
- **Gerador de QR Code dinâmico** (renova a cada 5 minutos)
- Relatório de presenças com filtros
- Exportação para **CSV**

### Segurança
- QR Codes expiram a cada 5 minutos (anti-fraude)
- Validação de GPS com raio configurável
- Row Level Security (RLS) no banco de dados
- Presença de uso único por aluno/turma/dia

---

## 🛠️ Tecnologias

| Camada     | Tecnologia                          |
|------------|-------------------------------------|
| Frontend   | HTML, CSS, JavaScript (puro)        |
| Backend    | Supabase (Auth + PostgreSQL + RLS)  |
| QR Code    | qrcode.js (geração) + html5-qrcode (leitura) |
| PWA        | Service Worker + manifest.json      |
| Planilha   | Google Sheets API (via Edge Functions) |

---

## 📦 Instalação e Configuração

### 1. Criar Projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e crie uma conta gratuita
2. Crie um novo projeto
3. Anote a **Project URL** e a **Anon Key** (Settings → API)

### 2. Criar o Banco de Dados

1. No painel do Supabase, vá para **SQL Editor**
2. Copie e cole todo o conteúdo de `database/schema.sql`
3. Execute o SQL

### 3. Configurar o Projeto

1. Abra o arquivo `js/config.js`
2. Substitua os valores:

```javascript
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_ANON_KEY = 'eyJ... (sua anon key)';
```

### 4. Configurar Autenticação

No Supabase Dashboard:
1. Vá para **Authentication → Settings**
2. Em **Email**, desabilite "Confirm email" (para facilitar testes)
3. Ou mantenha habilitado e configure um servidor SMTP

### 5. Criar Primeiro Professor

Execute no SQL Editor do Supabase:

```sql
-- Primeiro, cadastre o professor pelo site (formulário de cadastro)
-- Depois, altere o role para 'professor':
UPDATE perfis SET role = 'professor' WHERE matricula = 'MATRICULA_DO_PROFESSOR';
```

Ou cadastre diretamente:

```sql
-- Criar usuário no auth (via Dashboard → Authentication → Users → Add User)
-- Depois insira o perfil:
INSERT INTO perfis (id, nome, matricula, email, role)
VALUES ('UUID_DO_USER_CRIADO', 'Nome do Professor', 'PROF001', 'professor@email.com', 'professor');
```

### 6. Deploy

Como é um site estático, basta hospedar em qualquer serviço:

**Netlify:**
1. Arraste a pasta do projeto para [app.netlify.com](https://app.netlify.com)
2. Pronto!

**GitHub Pages:**
1. Suba o projeto para um repositório GitHub
2. Settings → Pages → Source: main branch

**Vercel:**
1. Conecte o repositório em [vercel.com](https://vercel.com)
2. Deploy automático

---

## 📁 Estrutura do Projeto

```
Projeto/
├── index.html              # Página de login/cadastro
├── presenca.html           # Página de confirmação via QR Code
├── manifest.json           # PWA manifest
├── sw.js                   # Service Worker
├── css/
│   └── style.css           # CSS global (mobile-first, dark mode)
├── js/
│   ├── config.js           # Configuração do Supabase
│   ├── utils.js            # Utilitários (toast, modal, GPS, etc.)
│   └── auth.js             # Módulo de autenticação
├── aluno/
│   ├── index.html          # Painel do aluno (aulas do dia)
│   └── historico.html      # Histórico de presenças
├── professor/
│   └── index.html          # Painel completo do professor
└── database/
    └── schema.sql          # Schema completo do PostgreSQL
```

---

## 🔄 Fluxo de Uso

### Aluno marca presença via QR Code:
1. Professor clica "Iniciar Aula" → QR Code dinâmico aparece na tela
2. Aluno abre o celular e escaneia o QR Code
3. Sistema verifica: token válido → aluno logado → matriculado na turma → GPS dentro do raio
4. Presença registrada com status (Presente ou Atrasado + minutos)

### Aluno marca presença manualmente:
1. Aluno abre o app → vê aulas do dia
2. Clica "Marcar Presença" na aula em andamento
3. Sistema valida GPS
4. Presença registrada

---

## 📊 Sincronização com Google Sheets (opcional)

Para sincronizar presenças com uma planilha Google:

1. Crie um projeto no [Google Cloud Console](https://console.cloud.google.com)
2. Habilite a **Google Sheets API**
3. Crie uma **Service Account** e baixe o JSON de credenciais
4. Compartilhe a planilha com o email da service account
5. Crie uma **Supabase Edge Function** com a lógica de sincronização
6. Configure um **Database Webhook** no Supabase para chamar a função a cada INSERT em `presencas`

---

## 📝 Licença

Projeto educacional — uso livre.
