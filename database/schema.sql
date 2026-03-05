-- ============================================
-- SCHEMA DO BANCO DE DADOS — SUPABASE (PostgreSQL)
-- Sistema de Presença Digital
-- ============================================
-- INSTRUÇÕES:
-- 1. Acesse o painel do Supabase → SQL Editor
-- 2. Cole todo este SQL e execute
-- ============================================

-- Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABELA: perfis
-- ============================================
CREATE TABLE perfis (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome VARCHAR(200) NOT NULL,
  matricula VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(200) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'aluno' CHECK (role IN ('aluno', 'professor')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_perfis_matricula ON perfis(matricula);
CREATE INDEX idx_perfis_role ON perfis(role);

-- RLS
ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;

-- Qualquer usuário autenticado pode ler perfis (necessário para buscas)
CREATE POLICY "Perfis: leitura autenticada"
  ON perfis FOR SELECT
  TO authenticated
  USING (true);

-- Usuário pode atualizar apenas seu próprio perfil
CREATE POLICY "Perfis: atualizar próprio"
  ON perfis FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Inserção durante cadastro (service role ou trigger)
CREATE POLICY "Perfis: inserir próprio"
  ON perfis FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);


-- ============================================
-- TABELA: disciplinas
-- ============================================
CREATE TABLE disciplinas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome VARCHAR(200) NOT NULL,
  professor_id UUID NOT NULL REFERENCES perfis(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_disciplinas_professor ON disciplinas(professor_id);

ALTER TABLE disciplinas ENABLE ROW LEVEL SECURITY;

-- Professor lê suas disciplinas; alunos lêem todas (para ver nome)
CREATE POLICY "Disciplinas: leitura autenticada"
  ON disciplinas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Disciplinas: professor CRUD"
  ON disciplinas FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM perfis WHERE id = auth.uid() AND role = 'professor')
    AND professor_id = auth.uid()
  );

CREATE POLICY "Disciplinas: professor atualizar"
  ON disciplinas FOR UPDATE
  TO authenticated
  USING (professor_id = auth.uid());

CREATE POLICY "Disciplinas: professor deletar"
  ON disciplinas FOR DELETE
  TO authenticated
  USING (professor_id = auth.uid());


-- ============================================
-- TABELA: turmas
-- ============================================
CREATE TABLE turmas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  disciplina_id UUID NOT NULL REFERENCES disciplinas(id) ON DELETE CASCADE,
  nome_turma VARCHAR(100) NOT NULL,
  dia_semana SMALLINT NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  hora_inicio TIME NOT NULL,
  hora_fim TIME NOT NULL,
  sala VARCHAR(100),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  raio_metros INTEGER DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_turmas_disciplina ON turmas(disciplina_id);
CREATE INDEX idx_turmas_dia ON turmas(dia_semana);

ALTER TABLE turmas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Turmas: leitura autenticada"
  ON turmas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Turmas: professor inserir"
  ON turmas FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM disciplinas d
      WHERE d.id = disciplina_id AND d.professor_id = auth.uid()
    )
  );

CREATE POLICY "Turmas: professor atualizar"
  ON turmas FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM disciplinas d
      WHERE d.id = disciplina_id AND d.professor_id = auth.uid()
    )
  );

CREATE POLICY "Turmas: professor deletar"
  ON turmas FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM disciplinas d
      WHERE d.id = disciplina_id AND d.professor_id = auth.uid()
    )
  );


-- ============================================
-- TABELA: turma_alunos (relação N:N)
-- ============================================
CREATE TABLE turma_alunos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  turma_id UUID NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  aluno_id UUID NOT NULL REFERENCES perfis(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(turma_id, aluno_id)
);

CREATE INDEX idx_turma_alunos_turma ON turma_alunos(turma_id);
CREATE INDEX idx_turma_alunos_aluno ON turma_alunos(aluno_id);

ALTER TABLE turma_alunos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "TurmaAlunos: leitura autenticada"
  ON turma_alunos FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "TurmaAlunos: professor inserir"
  ON turma_alunos FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );

CREATE POLICY "TurmaAlunos: professor deletar"
  ON turma_alunos FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );


-- ============================================
-- TABELA: qr_tokens
-- ============================================
CREATE TABLE qr_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  turma_id UUID NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  token UUID NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  expira_em TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_qr_tokens_token ON qr_tokens(token);
CREATE INDEX idx_qr_tokens_turma ON qr_tokens(turma_id);

ALTER TABLE qr_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "QRTokens: leitura autenticada"
  ON qr_tokens FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "QRTokens: professor inserir"
  ON qr_tokens FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );

CREATE POLICY "QRTokens: professor deletar"
  ON qr_tokens FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );


-- ============================================
-- TABELA: presencas
-- ============================================
CREATE TABLE presencas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  aluno_id UUID NOT NULL REFERENCES perfis(id) ON DELETE CASCADE,
  turma_id UUID NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  hora_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status VARCHAR(20) NOT NULL DEFAULT 'presente' CHECK (status IN ('presente', 'atrasado', 'ausente')),
  minutos_atraso INTEGER DEFAULT 0,
  latitude_aluno DOUBLE PRECISION,
  longitude_aluno DOUBLE PRECISION,
  distancia_metros INTEGER,
  metodo VARCHAR(20) DEFAULT 'qrcode' CHECK (metodo IN ('qrcode', 'manual')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(aluno_id, turma_id, data)
);

CREATE INDEX idx_presencas_aluno ON presencas(aluno_id);
CREATE INDEX idx_presencas_turma ON presencas(turma_id);
CREATE INDEX idx_presencas_data ON presencas(data);
CREATE INDEX idx_presencas_aluno_data ON presencas(aluno_id, data);

ALTER TABLE presencas ENABLE ROW LEVEL SECURITY;

-- Aluno lê apenas suas presenças
CREATE POLICY "Presencas: aluno lê próprias"
  ON presencas FOR SELECT
  TO authenticated
  USING (
    aluno_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );

-- Aluno pode inserir sua própria presença
CREATE POLICY "Presencas: aluno inserir"
  ON presencas FOR INSERT
  TO authenticated
  WITH CHECK (aluno_id = auth.uid());

-- Professor pode atualizar presenças de suas turmas (ex: marcar ausente)
CREATE POLICY "Presencas: professor atualizar"
  ON presencas FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM turmas t
      JOIN disciplinas d ON d.id = t.disciplina_id
      WHERE t.id = turma_id AND d.professor_id = auth.uid()
    )
  );


-- ============================================
-- VIEWS AUXILIARES
-- ============================================

-- View: presenças com dados completos (para listagem)
CREATE OR REPLACE VIEW presencas_completas AS
SELECT
  p.id,
  p.data,
  p.hora_registro,
  p.status,
  p.minutos_atraso,
  p.distancia_metros,
  p.metodo,
  a.nome AS aluno_nome,
  a.matricula AS aluno_matricula,
  t.nome_turma,
  t.hora_inicio,
  t.sala,
  d.nome AS disciplina_nome
FROM presencas p
JOIN perfis a ON a.id = p.aluno_id
JOIN turmas t ON t.id = p.turma_id
JOIN disciplinas d ON d.id = t.disciplina_id;


-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

-- Função: buscar turmas do aluno para hoje
CREATE OR REPLACE FUNCTION turmas_do_aluno_hoje(p_aluno_id UUID)
RETURNS TABLE (
  turma_id UUID,
  nome_turma VARCHAR,
  disciplina_nome VARCHAR,
  hora_inicio TIME,
  hora_fim TIME,
  sala VARCHAR,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  raio_metros INTEGER,
  ja_marcou BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id AS turma_id,
    t.nome_turma,
    d.nome AS disciplina_nome,
    t.hora_inicio,
    t.hora_fim,
    t.sala,
    t.latitude,
    t.longitude,
    t.raio_metros,
    EXISTS (
      SELECT 1 FROM presencas pr
      WHERE pr.aluno_id = p_aluno_id
        AND pr.turma_id = t.id
        AND pr.data = CURRENT_DATE
    ) AS ja_marcou
  FROM turma_alunos ta
  JOIN turmas t ON t.id = ta.turma_id
  JOIN disciplinas d ON d.id = t.disciplina_id
  WHERE ta.aluno_id = p_aluno_id
    AND t.dia_semana = EXTRACT(DOW FROM CURRENT_DATE)::SMALLINT
  ORDER BY t.hora_inicio;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Função: validar token QR e retornar dados da turma
CREATE OR REPLACE FUNCTION validar_qr_token(p_token UUID)
RETURNS TABLE (
  turma_id UUID,
  nome_turma VARCHAR,
  disciplina_nome VARCHAR,
  hora_inicio TIME,
  hora_fim TIME,
  sala VARCHAR,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  raio_metros INTEGER,
  token_valido BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id AS turma_id,
    t.nome_turma,
    d.nome AS disciplina_nome,
    t.hora_inicio,
    t.hora_fim,
    t.sala,
    t.latitude,
    t.longitude,
    t.raio_metros,
    (qt.expira_em > NOW()) AS token_valido
  FROM qr_tokens qt
  JOIN turmas t ON t.id = qt.turma_id
  JOIN disciplinas d ON d.id = t.disciplina_id
  WHERE qt.token = p_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
