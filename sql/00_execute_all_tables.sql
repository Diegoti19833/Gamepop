-- =====================================================
-- SCRIPT PRINCIPAL - CRIAÇÃO DE TODAS AS TABELAS
-- Descrição: Executa todos os scripts de criação na ordem correta
-- =====================================================

-- IMPORTANTE: Execute este script no SQL Editor do Supabase
-- Ele criará todas as tabelas, índices, triggers e funções necessárias

\echo '🚀 Iniciando criação do banco de dados PET CLASS...'

-- =====================================================
-- 1. TABELA USERS
-- =====================================================
\echo '📝 Criando tabela users...'

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(50) NOT NULL DEFAULT 'funcionario' CHECK (role IN ('funcionario', 'gerente', 'admin')),
    total_xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 100,
    current_streak INTEGER DEFAULT 0,
    max_streak INTEGER DEFAULT 0,
    lessons_completed INTEGER DEFAULT 0,
    quizzes_completed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_total_xp ON users(total_xp DESC);
CREATE INDEX IF NOT EXISTS idx_users_current_streak ON users(current_streak DESC);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 2. TABELA TRAILS
-- =====================================================
\echo '📝 Criando tabela trails...'

CREATE TABLE IF NOT EXISTS trails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    icon_url TEXT,
    color VARCHAR(7) DEFAULT '#3B82F6',
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    estimated_duration INTEGER DEFAULT 60,
    total_lessons INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trails_is_active ON trails(is_active);
CREATE INDEX IF NOT EXISTS idx_trails_order_index ON trails(order_index);
CREATE INDEX IF NOT EXISTS idx_trails_difficulty ON trails(difficulty_level);

DROP TRIGGER IF EXISTS update_trails_updated_at ON trails;
CREATE TRIGGER update_trails_updated_at
    BEFORE UPDATE ON trails
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 3. TABELA LESSONS
-- =====================================================
\echo '📝 Criando tabela lessons...'

CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trail_id UUID NOT NULL REFERENCES trails(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content TEXT,
    video_url TEXT,
    duration INTEGER DEFAULT 15,
    xp_reward INTEGER DEFAULT 10,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    lesson_type VARCHAR(50) DEFAULT 'video' CHECK (lesson_type IN ('video', 'text', 'interactive', 'quiz')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lessons_trail_id ON lessons(trail_id);
CREATE INDEX IF NOT EXISTS idx_lessons_order_index ON lessons(order_index);
CREATE INDEX IF NOT EXISTS idx_lessons_is_active ON lessons(is_active);
CREATE INDEX IF NOT EXISTS idx_lessons_type ON lessons(lesson_type);

DROP TRIGGER IF EXISTS update_lessons_updated_at ON lessons;
CREATE TRIGGER update_lessons_updated_at
    BEFORE UPDATE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para atualizar total_lessons na trilha
CREATE OR REPLACE FUNCTION update_trail_lesson_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE trails 
        SET total_lessons = (
            SELECT COUNT(*) 
            FROM lessons 
            WHERE trail_id = NEW.trail_id AND is_active = true
        )
        WHERE id = NEW.trail_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE trails 
        SET total_lessons = (
            SELECT COUNT(*) 
            FROM lessons 
            WHERE trail_id = OLD.trail_id AND is_active = true
        )
        WHERE id = OLD.trail_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE trails 
        SET total_lessons = (
            SELECT COUNT(*) 
            FROM lessons 
            WHERE trail_id = NEW.trail_id AND is_active = true
        )
        WHERE id = NEW.trail_id;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_trail_lesson_count_trigger ON lessons;
CREATE TRIGGER update_trail_lesson_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON lessons
    FOR EACH ROW
    EXECUTE FUNCTION update_trail_lesson_count();

-- =====================================================
-- 4. TABELA QUIZ_OPTIONS
-- =====================================================
\echo '📝 Criando tabela quiz_options...'

CREATE TABLE IF NOT EXISTS quiz_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quiz_options_lesson_id ON quiz_options(lesson_id);
CREATE INDEX IF NOT EXISTS idx_quiz_options_order_index ON quiz_options(order_index);
CREATE INDEX IF NOT EXISTS idx_quiz_options_is_correct ON quiz_options(is_correct);

DROP TRIGGER IF EXISTS update_quiz_options_updated_at ON quiz_options;
CREATE TRIGGER update_quiz_options_updated_at
    BEFORE UPDATE ON quiz_options
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 15. FUNÇÕES DA LOJA
-- =====================================================
\echo '🛒 Criando funções da loja...'

-- Função principal para comprar item da loja
CREATE OR REPLACE FUNCTION purchase_store_item(
    user_id_param UUID,
    item_id_param UUID,
    quantity_param INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    item_record RECORD;
    user_coins INTEGER;
    total_cost INTEGER;
    unit_price INTEGER;
BEGIN
    -- Buscar item da loja
    SELECT * INTO item_record
    FROM store_items 
    WHERE id = item_id_param AND is_available = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Item não encontrado ou indisponível');
    END IF;
    
    -- Buscar moedas do usuário
    SELECT COALESCE(coins, 0) INTO user_coins
    FROM users 
    WHERE id = user_id_param;
    
    -- Calcular preços
    unit_price := item_record.price;
    total_cost := unit_price * quantity_param;
    
    -- Verificar se o usuário tem moedas suficientes
    IF user_coins < total_cost THEN
        RETURN json_build_object('success', false, 'error', 'Moedas insuficientes');
    END IF;
    
    -- Processar a compra
    BEGIN
        -- Debitar moedas do usuário
        UPDATE users 
        SET coins = coins - total_cost
        WHERE id = user_id_param;
        
        -- Registrar a compra (usando a estrutura correta da tabela)
        INSERT INTO user_purchases (
            user_id, 
            item_id, 
            quantity, 
            unit_price, 
            total_price, 
            purchase_date
        )
        VALUES (
            user_id_param, 
            item_id_param, 
            quantity_param, 
            unit_price, 
            total_cost, 
            NOW()
        );
        
        RETURN json_build_object(
            'success', true, 
            'message', 'Compra realizada com sucesso',
            'item_name', item_record.name,
            'quantity', quantity_param,
            'unit_price', unit_price,
            'total_cost', total_cost,
            'remaining_coins', user_coins - total_cost
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Erro interno ao processar compra: ' || SQLERRM);
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para usar item da loja
CREATE OR REPLACE FUNCTION use_store_item(
    user_id_param UUID,
    item_id_param UUID,
    quantity_param INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    user_item RECORD;
    item_data RECORD;
    remaining_quantity INTEGER;
BEGIN
    -- Verificar se o usuário possui o item
    SELECT * INTO user_item
    FROM user_purchases
    WHERE user_id = user_id_param AND item_id = item_id_param AND is_active = true
    ORDER BY purchase_date DESC
    LIMIT 1;
    
    IF user_item IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Item não encontrado no inventário');
    END IF;
    
    IF user_item.quantity < quantity_param THEN
        RETURN json_build_object('success', false, 'error', 'Quantidade insuficiente');
    END IF;
    
    -- Buscar dados do item
    SELECT * INTO item_data
    FROM store_items
    WHERE id = item_id_param;
    
    -- Calcular quantidade restante
    remaining_quantity := user_item.quantity - quantity_param;
    
    -- Processar uso do item
    BEGIN
        IF remaining_quantity > 0 THEN
            -- Reduzir quantidade no inventário
            UPDATE user_purchases
            SET quantity = remaining_quantity
            WHERE id = user_item.id;
        ELSE
            -- Marcar item como inativo se quantidade chegou a zero
            UPDATE user_purchases
            SET is_active = false, quantity = 0
            WHERE id = user_item.id;
        END IF;
        
        RETURN json_build_object(
            'success', true,
            'message', 'Item usado com sucesso',
            'item_name', item_data.name,
            'quantity_used', quantity_param,
            'remaining_quantity', remaining_quantity
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Erro interno ao usar item: ' || SQLERRM);
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para listar itens do usuário
CREATE OR REPLACE FUNCTION get_user_inventory(user_id_param UUID)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT COALESCE(json_agg(
            json_build_object(
                'purchase_id', up.id,
                'item_id', si.id,
                'item_name', si.name,
                'item_type', si.item_type,
                'quantity', up.quantity,
                'unit_price', up.unit_price,
                'total_price', up.total_price,
                'purchase_date', up.purchase_date,
                'is_active', up.is_active
            )
        ), '[]'::json)
        FROM user_purchases up
        JOIN store_items si ON up.item_id = si.id
        WHERE up.user_id = user_id_param AND up.is_active = true AND up.quantity > 0
        ORDER BY up.purchase_date DESC
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

\echo '✅ Funções da loja criadas com sucesso!'

-- =====================================================
-- SISTEMA DE PONTUAÇÃO POR TRILHA COMPLETADA
-- =====================================================

\echo '🎯 Criando sistema de pontuação por trilha completada...'

-- Função para verificar se uma trilha foi completada por um usuário
CREATE OR REPLACE FUNCTION check_trail_completion(p_user_id UUID, p_trail_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
BEGIN
    -- Conta o total de lições ativas na trilha
    SELECT COUNT(*) INTO total_lessons
    FROM lessons
    WHERE trail_id = p_trail_id AND is_active = true;
    
    -- Conta quantas lições foram completadas pelo usuário
    SELECT COUNT(DISTINCT lesson_id) INTO completed_lessons
    FROM user_progress
    WHERE user_id = p_user_id 
      AND trail_id = p_trail_id 
      AND progress_type = 'lesson_completed'
      AND completed_at IS NOT NULL;
    
    -- Retorna true se todas as lições foram completadas
    RETURN (total_lessons > 0 AND completed_lessons >= total_lessons);
END;
$$ LANGUAGE plpgsql;

-- Função para calcular pontos de bônus por trilha completada
CREATE OR REPLACE FUNCTION calculate_trail_completion_bonus(p_trail_id UUID)
RETURNS INTEGER AS $$
DECLARE
    difficulty_level INTEGER;
    total_lessons INTEGER;
    base_bonus INTEGER := 100; -- Bônus base
    difficulty_multiplier DECIMAL;
BEGIN
    -- Busca o nível de dificuldade e total de lições da trilha
    SELECT t.difficulty_level, t.total_lessons
    INTO difficulty_level, total_lessons
    FROM trails t
    WHERE t.id = p_trail_id;
    
    -- Define multiplicador baseado na dificuldade
    CASE difficulty_level
        WHEN 1 THEN difficulty_multiplier := 1.0;   -- Iniciante
        WHEN 2 THEN difficulty_multiplier := 1.5;   -- Intermediário
        WHEN 3 THEN difficulty_multiplier := 2.0;   -- Avançado
        ELSE difficulty_multiplier := 1.0;
    END CASE;
    
    -- Calcula bônus: base + (10 pontos por lição) * multiplicador de dificuldade
    RETURN ROUND(base_bonus + (total_lessons * 10) * difficulty_multiplier);
END;
$$ LANGUAGE plpgsql;

-- Função para processar conclusão de trilha e dar pontos extras
CREATE OR REPLACE FUNCTION process_trail_completion(p_user_id UUID, p_trail_id UUID)
RETURNS VOID AS $$
DECLARE
    trail_completed BOOLEAN;
    completion_bonus INTEGER;
    existing_completion UUID;
BEGIN
    -- Verifica se a trilha foi completada
    trail_completed := check_trail_completion(p_user_id, p_trail_id);
    
    IF trail_completed THEN
        -- Verifica se já existe um registro de conclusão da trilha
        SELECT id INTO existing_completion
        FROM user_progress
        WHERE user_id = p_user_id 
          AND trail_id = p_trail_id 
          AND progress_type = 'trail_completed'
          AND completed_at IS NOT NULL;
        
        -- Se não existe registro de conclusão, cria um
        IF existing_completion IS NULL THEN
            -- Calcula o bônus de conclusão
            completion_bonus := calculate_trail_completion_bonus(p_trail_id);
            
            -- Insere registro de trilha completada com bônus
            INSERT INTO user_progress (
                user_id,
                trail_id,
                progress_type,
                completion_percentage,
                xp_earned,
                completed_at
            ) VALUES (
                p_user_id,
                p_trail_id,
                'trail_completed',
                100,
                completion_bonus,
                NOW()
            );
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Função trigger para verificar conclusão de trilha após completar lição
CREATE OR REPLACE FUNCTION check_trail_completion_on_lesson_complete()
RETURNS TRIGGER AS $$
BEGIN
    -- Só processa se for uma conclusão de lição
    IF NEW.progress_type = 'lesson_completed' AND NEW.completed_at IS NOT NULL THEN
        -- Verifica se a trilha foi completada e processa bônus
        PERFORM process_trail_completion(NEW.user_id, NEW.trail_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para verificar conclusão de trilha automaticamente
DROP TRIGGER IF EXISTS check_trail_completion_trigger ON user_progress;
CREATE TRIGGER check_trail_completion_trigger
    AFTER INSERT OR UPDATE ON user_progress
    FOR EACH ROW
    EXECUTE FUNCTION check_trail_completion_on_lesson_complete();

-- Função para obter estatísticas de trilhas do usuário
CREATE OR REPLACE FUNCTION get_user_trail_stats(p_user_id UUID)
RETURNS TABLE (
    trail_id UUID,
    trail_title VARCHAR,
    total_lessons INTEGER,
    completed_lessons INTEGER,
    completion_percentage INTEGER,
    is_completed BOOLEAN,
    completion_date TIMESTAMP WITH TIME ZONE,
    total_xp_earned INTEGER,
    completion_bonus INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as trail_id,
        t.title as trail_title,
        t.total_lessons,
        COALESCE(lesson_progress.completed_count, 0) as completed_lessons,
        CASE 
            WHEN t.total_lessons > 0 THEN 
                ROUND((COALESCE(lesson_progress.completed_count, 0)::DECIMAL / t.total_lessons) * 100)::INTEGER
            ELSE 0
        END as completion_percentage,
        COALESCE(trail_completion.is_completed, false) as is_completed,
        trail_completion.completed_at as completion_date,
        COALESCE(total_xp.total_earned, 0) as total_xp_earned,
        COALESCE(trail_completion.completion_bonus, 0) as completion_bonus
    FROM trails t
    LEFT JOIN (
        -- Conta lições completadas por trilha
        SELECT 
            trail_id,
            COUNT(DISTINCT lesson_id) as completed_count
        FROM user_progress
        WHERE user_id = p_user_id 
          AND progress_type = 'lesson_completed'
          AND completed_at IS NOT NULL
        GROUP BY trail_id
    ) lesson_progress ON t.id = lesson_progress.trail_id
    LEFT JOIN (
        -- Verifica se trilha foi completada
        SELECT 
            trail_id,
            true as is_completed,
            completed_at,
            xp_earned as completion_bonus
        FROM user_progress
        WHERE user_id = p_user_id 
          AND progress_type = 'trail_completed'
          AND completed_at IS NOT NULL
    ) trail_completion ON t.id = trail_completion.trail_id
    LEFT JOIN (
        -- Soma XP total ganho na trilha
        SELECT 
            trail_id,
            SUM(xp_earned) as total_earned
        FROM user_progress
        WHERE user_id = p_user_id
        GROUP BY trail_id
    ) total_xp ON t.id = total_xp.trail_id
    WHERE t.is_active = true
    ORDER BY t.order_index, t.created_at;
END;
$$ LANGUAGE plpgsql;

-- Atualizar o tipo de progresso para incluir 'trail_completed'
ALTER TABLE user_progress 
DROP CONSTRAINT IF EXISTS user_progress_progress_type_check;

ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_progress_type_check 
CHECK (progress_type IN ('trail_started', 'lesson_completed', 'quiz_completed', 'trail_completed'));

\echo '✅ Sistema de pontuação por trilha completada criado com sucesso!'

-- =====================================================
-- TRILHAS ESPECÍFICAS POR GRUPO DE FUNCIONÁRIOS
-- =====================================================

-- Atualizar tabela users para incluir papel 'caixa'
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('funcionario', 'gerente', 'admin', 'caixa'));

-- Adicionar colunas para controle de acesso por grupo na tabela trails
ALTER TABLE trails 
ADD COLUMN IF NOT EXISTS target_roles TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'geral';

-- Criar índices para as novas colunas
CREATE INDEX IF NOT EXISTS idx_trails_target_roles ON trails USING GIN (target_roles);
CREATE INDEX IF NOT EXISTS idx_trails_category ON trails (category);

-- Função para verificar se usuário pode acessar trilha
CREATE OR REPLACE FUNCTION user_can_access_trail(p_user_role TEXT, p_trail_target_roles TEXT[])
RETURNS BOOLEAN AS $$
BEGIN
    -- Se a trilha não tem restrições de papel, todos podem acessar
    IF p_trail_target_roles IS NULL OR array_length(p_trail_target_roles, 1) IS NULL THEN
        RETURN TRUE;
    END IF;
    
    -- Verifica se o papel do usuário está na lista de papéis permitidos
    RETURN p_user_role = ANY(p_trail_target_roles);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRILHAS ESPECÍFICAS PARA FUNCIONÁRIOS
-- =====================================================

-- Trilha 1: Atendimento ao Cliente - Funcionário
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Atendimento ao Cliente - Funcionário', 'Aprenda as técnicas essenciais de atendimento ao cliente, comunicação efetiva e resolução de problemas básicos.', 'https://img.icons8.com/fluency/96/customer-support.png', '#4CAF50', 1, 180, 4, true, 1, '{"funcionario"}', 'atendimento');

-- Trilha 2: Procedimentos Operacionais Básicos
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Procedimentos Operacionais Básicos', 'Domine os procedimentos operacionais fundamentais, normas de segurança e organização do ambiente de trabalho.', 'https://img.icons8.com/fluency/96/checklist.png', '#2196F3', 1, 150, 3, true, 2, '{"funcionario"}', 'operacional');

-- =====================================================
-- TRILHAS ESPECÍFICAS PARA GERENTES
-- =====================================================

-- Trilha 3: Liderança e Gestão de Equipes
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Liderança e Gestão de Equipes', 'Desenvolva habilidades de liderança, motivação de equipes e gestão de pessoas para maximizar resultados.', 'https://img.icons8.com/fluency/96/leadership.png', '#FF9800', 3, 240, 3, true, 3, '{"gerente"}', 'lideranca');

-- Trilha 4: Gestão Financeira e KPIs
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Gestão Financeira e KPIs', 'Aprenda a interpretar indicadores financeiros, controlar custos e tomar decisões baseadas em dados.', 'https://img.icons8.com/fluency/96/financial-growth-analysis.png', '#9C27B0', 3, 200, 3, true, 4, '{"gerente"}', 'financeiro');

-- =====================================================
-- TRILHAS ESPECÍFICAS PARA CAIXAS
-- =====================================================

-- Trilha 5: Operações de Caixa e Pagamentos
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Operações de Caixa e Pagamentos', 'Domine todas as operações de caixa, formas de pagamento e procedimentos de segurança financeira.', 'https://img.icons8.com/fluency/96/cash-register.png', '#F44336', 2, 160, 3, true, 5, '{"caixa"}', 'financeiro');

-- Trilha 6: Atendimento Rápido e Eficiente no Caixa
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Atendimento Rápido e Eficiente no Caixa', 'Aprenda técnicas para agilizar o atendimento no caixa mantendo a qualidade e satisfação do cliente.', 'https://img.icons8.com/fluency/96/speed.png', '#00BCD4', 2, 120, 3, true, 6, '{"caixa"}', 'atendimento');

-- =====================================================
-- TRILHAS COMPARTILHADAS (TODOS OS GRUPOS)
-- =====================================================

-- Trilha 7: Segurança e Compliance Empresarial
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Segurança e Compliance Empresarial', 'Entenda as normas de compliance, LGPD, segurança da informação e ética empresarial.', 'https://img.icons8.com/fluency/96/security-checked.png', '#795548', 2, 180, 2, true, 7, '{"funcionario", "gerente", "caixa"}', 'compliance');

-- Trilha 8: Cultura e Valores Organizacionais
INSERT INTO trails (id, title, description, icon_url, color, difficulty_level, estimated_duration, total_lessons, is_active, order_index, target_roles, category) VALUES
(gen_random_uuid(), 'Cultura e Valores Organizacionais', 'Conheça a cultura, missão, visão e valores da empresa e como aplicá-los no dia a dia.', 'https://img.icons8.com/fluency/96/company.png', '#607D8B', 1, 90, 2, true, 8, '{"funcionario", "gerente", "caixa"}', 'cultura');

\echo '✅ Trilhas específicas por grupo criadas com sucesso!'

-- =====================================================
-- LIÇÕES PARA TRILHAS ESPECÍFICAS POR GRUPO
-- =====================================================

-- Lições para Funcionários - Atendimento ao Cliente
DO $$ 
DECLARE 
    trail_funcionario_atendimento UUID;
BEGIN
    SELECT id INTO trail_funcionario_atendimento 
    FROM trails 
    WHERE title = 'Atendimento ao Cliente - Funcionário';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_funcionario_atendimento, 'Fundamentos do Atendimento', 'Aprenda os princípios básicos do atendimento ao cliente e a importância da primeira impressão.', 'Nesta lição você aprenderá sobre os fundamentos do atendimento ao cliente, incluindo a importância do primeiro contato, postura profissional e criação de um ambiente acolhedor.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 25, 50, 1, 'video'),
    (trail_funcionario_atendimento, 'Comunicação Efetiva', 'Desenvolva habilidades de comunicação clara, escuta ativa e linguagem corporal adequada.', 'Explore técnicas de comunicação efetiva, incluindo escuta ativa, linguagem verbal e não-verbal, e como adaptar sua comunicação para diferentes tipos de clientes.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 30, 60, 2, 'video'),
    (trail_funcionario_atendimento, 'Resolução de Problemas Básicos', 'Aprenda a identificar, analisar e resolver problemas comuns no atendimento ao cliente.', 'Desenvolva habilidades para identificar problemas, fazer perguntas adequadas e encontrar soluções práticas para situações do dia a dia.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 35, 70, 3, 'video'),
    (trail_funcionario_atendimento, 'Lidando com Reclamações', 'Aprenda técnicas para lidar com clientes insatisfeitos e transformar reclamações em oportunidades.', 'Descubra como manter a calma, demonstrar empatia e encontrar soluções satisfatórias para clientes com reclamações.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 40, 80, 4, 'video');
END $$;

-- Lições para Funcionários - Procedimentos Operacionais
DO $$ 
DECLARE 
    trail_funcionario_operacional UUID;
BEGIN
    SELECT id INTO trail_funcionario_operacional 
    FROM trails 
    WHERE title = 'Procedimentos Operacionais Básicos';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_funcionario_operacional, 'Normas de Segurança no Trabalho', 'Conheça as principais normas de segurança e como aplicá-las no ambiente de trabalho.', 'Aprenda sobre equipamentos de proteção individual, procedimentos de segurança e como prevenir acidentes no trabalho.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 30, 60, 1, 'video'),
    (trail_funcionario_operacional, 'Organização do Ambiente de Trabalho', 'Aprenda técnicas de organização e metodologia 5S para manter o ambiente produtivo.', 'Descubra como organizar seu espaço de trabalho, implementar a metodologia 5S e manter a produtividade.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 25, 50, 2, 'video'),
    (trail_funcionario_operacional, 'Protocolos de Emergência', 'Conheça os procedimentos em caso de emergências e situações de risco.', 'Aprenda sobre planos de evacuação, primeiros socorros básicos e como agir em diferentes tipos de emergência.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 35, 70, 3, 'video');
END $$;

-- Lições para Gerentes - Liderança
DO $$ 
DECLARE 
    trail_gerente_lideranca UUID;
BEGIN
    SELECT id INTO trail_gerente_lideranca 
    FROM trails 
    WHERE title = 'Liderança e Gestão de Equipes';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_gerente_lideranca, 'Estilos de Liderança', 'Conheça diferentes estilos de liderança e quando aplicar cada um.', 'Explore os principais estilos de liderança: autocrático, democrático, delegativo e situacional, e aprenda quando usar cada abordagem.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 45, 90, 1, 'video'),
    (trail_gerente_lideranca, 'Motivação e Engajamento', 'Aprenda técnicas para motivar sua equipe e aumentar o engajamento.', 'Descubra teorias de motivação, como identificar o que motiva cada pessoa e estratégias para manter a equipe engajada.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 50, 100, 2, 'video'),
    (trail_gerente_lideranca, 'Feedback e Desenvolvimento', 'Domine a arte de dar feedback construtivo e desenvolver sua equipe.', 'Aprenda técnicas de feedback efetivo, como conduzir conversas de desenvolvimento e criar planos de crescimento.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 40, 80, 3, 'video');
END $$;

-- Lições para Gerentes - Gestão Financeira
DO $$ 
DECLARE 
    trail_gerente_financeiro UUID;
BEGIN
    SELECT id INTO trail_gerente_financeiro 
    FROM trails 
    WHERE title = 'Gestão Financeira e KPIs';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_gerente_financeiro, 'Indicadores de Performance (KPIs)', 'Aprenda a definir, medir e interpretar os principais KPIs do negócio.', 'Conheça os principais indicadores de performance, como defini-los corretamente e como usar os dados para tomar decisões.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 40, 80, 1, 'video'),
    (trail_gerente_financeiro, 'Controle de Custos e Orçamento', 'Domine técnicas de controle de custos e planejamento orçamentário.', 'Aprenda a elaborar orçamentos, controlar custos operacionais e identificar oportunidades de economia.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 45, 90, 2, 'video'),
    (trail_gerente_financeiro, 'Análise de Resultados', 'Aprenda a analisar demonstrativos financeiros e relatórios de performance.', 'Desenvolva habilidades para interpretar relatórios financeiros, identificar tendências e propor ações corretivas.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 50, 100, 3, 'video');
END $$;

-- Lições para Caixas - Operações
DO $$ 
DECLARE 
    trail_caixa_operacoes UUID;
BEGIN
    SELECT id INTO trail_caixa_operacoes 
    FROM trails 
    WHERE title = 'Operações de Caixa e Pagamentos';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_caixa_operacoes, 'Abertura e Fechamento de Caixa', 'Aprenda os procedimentos corretos para abertura e fechamento do caixa.', 'Conheça todos os passos para abrir e fechar o caixa corretamente, incluindo conferência de valores e documentação.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 30, 60, 1, 'video'),
    (trail_caixa_operacoes, 'Formas de Pagamento', 'Domine todas as formas de pagamento: dinheiro, cartão, PIX e outros.', 'Aprenda a processar diferentes formas de pagamento, incluindo procedimentos de segurança para cada modalidade.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 35, 70, 2, 'video'),
    (trail_caixa_operacoes, 'Segurança no Caixa', 'Conheça os procedimentos de segurança para operações de caixa.', 'Aprenda sobre identificação de notas falsas, procedimentos anti-fraude e como agir em situações suspeitas.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 40, 80, 3, 'video');
END $$;

-- Lições para Caixas - Atendimento Rápido
DO $$ 
DECLARE 
    trail_caixa_atendimento UUID;
BEGIN
    SELECT id INTO trail_caixa_atendimento 
    FROM trails 
    WHERE title = 'Atendimento Rápido e Eficiente no Caixa';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_caixa_atendimento, 'Técnicas de Agilidade', 'Aprenda técnicas para acelerar o atendimento sem perder qualidade.', 'Descubra métodos para otimizar o tempo de atendimento, organizar o espaço de trabalho e manter a eficiência.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 25, 50, 1, 'video'),
    (trail_caixa_atendimento, 'Gestão de Filas', 'Aprenda a gerenciar filas e reduzir o tempo de espera dos clientes.', 'Conheça estratégias para organizar filas, priorizar atendimentos e manter os clientes informados sobre o tempo de espera.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 30, 60, 2, 'video'),
    (trail_caixa_atendimento, 'Multitarefa no Caixa', 'Desenvolva habilidades para realizar múltiplas tarefas de forma eficiente.', 'Aprenda a equilibrar velocidade e precisão, gerenciar múltiplas demandas e manter a qualidade do atendimento.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 35, 70, 3, 'video');
END $$;

-- Lições para Trilhas Compartilhadas - Segurança e Compliance
DO $$ 
DECLARE 
    trail_seguranca UUID;
BEGIN
    SELECT id INTO trail_seguranca 
    FROM trails 
    WHERE title = 'Segurança e Compliance Empresarial';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_seguranca, 'LGPD e Proteção de Dados', 'Conheça a Lei Geral de Proteção de Dados e como aplicá-la no trabalho.', 'Aprenda sobre a LGPD, direitos dos titulares de dados, procedimentos de proteção e como lidar com dados pessoais.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 45, 90, 1, 'video'),
    (trail_seguranca, 'Compliance e Ética', 'Entenda os princípios de compliance e ética empresarial.', 'Explore conceitos de compliance, código de ética, conflitos de interesse e como tomar decisões éticas.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 40, 80, 2, 'video');
END $$;

-- Lições para Trilhas Compartilhadas - Cultura Organizacional
DO $$ 
DECLARE 
    trail_cultura UUID;
BEGIN
    SELECT id INTO trail_cultura 
    FROM trails 
    WHERE title = 'Cultura e Valores Organizacionais';
    
    INSERT INTO lessons (trail_id, title, description, content, video_url, duration_minutes, xp_reward, order_index, lesson_type) VALUES
    (trail_cultura, 'Missão, Visão e Valores', 'Conheça a missão, visão e valores da empresa e como vivenciá-los.', 'Aprenda sobre a identidade da empresa, seus propósitos e como incorporar os valores no dia a dia de trabalho.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 20, 40, 1, 'video'),
    (trail_cultura, 'Comportamentos e Atitudes', 'Desenvolva comportamentos alinhados com a cultura organizacional.', 'Descubra como demonstrar os valores da empresa através de suas ações, atitudes e relacionamentos no trabalho.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 25, 50, 2, 'video');
END $$;

\echo '✅ Lições específicas por grupo criadas com sucesso!'

-- =====================================================
-- QUIZZES ESPECÍFICOS PARA TRILHAS POR GRUPO
-- =====================================================

-- Quizzes para Funcionários - Atendimento ao Cliente
DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_funcionario_atendimento UUID;
BEGIN
    SELECT id INTO trail_funcionario_atendimento 
    FROM trails 
    WHERE title = 'Atendimento ao Cliente - Funcionário';
    
    -- Quiz para "Fundamentos do Atendimento"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_atendimento 
        AND title = 'Fundamentos do Atendimento'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_atendimento, 'Quiz: Fundamentos do Atendimento', 
         'Qual é o elemento mais importante no primeiro contato com o cliente?',
         '["Velocidade no atendimento", "Sorriso e cordialidade", "Conhecimento técnico", "Preço dos produtos"]',
         1, 'O sorriso e cordialidade criam uma primeira impressão positiva e estabelecem um ambiente acolhedor.', 
         25, 1, 1);
    END LOOP;
    
    -- Quiz para "Comunicação Efetiva"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_atendimento 
        AND title = 'Comunicação Efetiva'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_atendimento, 'Quiz: Comunicação Efetiva', 
         'O que caracteriza a escuta ativa no atendimento?',
         '["Falar mais que o cliente", "Interromper para dar soluções", "Prestar atenção total ao que o cliente diz", "Pensar na resposta enquanto o cliente fala"]',
         2, 'A escuta ativa envolve prestar atenção total ao cliente, demonstrando interesse genuíno em suas necessidades.', 
         30, 1, 1);
    END LOOP;
    
    -- Quiz para "Resolução de Problemas Básicos"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_atendimento 
        AND title = 'Resolução de Problemas Básicos'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_atendimento, 'Quiz: Resolução de Problemas', 
         'Qual é o primeiro passo para resolver um problema do cliente?',
         '["Oferecer uma solução imediata", "Entender completamente o problema", "Chamar o supervisor", "Verificar o sistema"]',
         1, 'É essencial entender completamente o problema antes de propor qualquer solução.', 
         35, 2, 1);
    END LOOP;
    
    -- Quiz para "Lidando com Reclamações"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_atendimento 
        AND title = 'Lidando com Reclamações'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_atendimento, 'Quiz: Lidando com Reclamações', 
         'Como você deve reagir quando um cliente está visivelmente irritado?',
         '["Defender a empresa imediatamente", "Manter a calma e demonstrar empatia", "Transferir para outro funcionário", "Explicar que não é sua culpa"]',
         1, 'Manter a calma e demonstrar empatia ajuda a acalmar o cliente e criar um ambiente para resolver o problema.', 
         40, 2, 1);
    END LOOP;
END $$;

-- Quizzes para Funcionários - Procedimentos Operacionais
DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_funcionario_operacional UUID;
BEGIN
    SELECT id INTO trail_funcionario_operacional 
    FROM trails 
    WHERE title = 'Procedimentos Operacionais Básicos';
    
    -- Quiz para "Normas de Segurança no Trabalho"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_operacional 
        AND title = 'Normas de Segurança no Trabalho'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_operacional, 'Quiz: Segurança no Trabalho', 
         'Quando você deve usar equipamentos de proteção individual (EPI)?',
         '["Apenas quando há fiscalização", "Somente em atividades perigosas", "Sempre que especificado nos procedimentos", "Apenas se sentir necessário"]',
         2, 'Os EPIs devem ser usados sempre que especificado nos procedimentos de segurança, independente da percepção pessoal de risco.', 
         30, 1, 1);
    END LOOP;
    
    -- Quiz para "Organização do Ambiente de Trabalho"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_operacional 
        AND title = 'Organização do Ambiente de Trabalho'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_operacional, 'Quiz: Organização do Trabalho', 
         'Qual é o principal benefício de manter o ambiente de trabalho organizado?',
         '["Impressionar os supervisores", "Aumentar a produtividade e segurança", "Facilitar a limpeza", "Seguir as regras da empresa"]',
         1, 'Um ambiente organizado aumenta a produtividade, reduz acidentes e melhora a qualidade do trabalho.', 
         25, 1, 1);
    END LOOP;
    
    -- Quiz para "Protocolos de Emergência"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_funcionario_operacional 
        AND title = 'Protocolos de Emergência'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_funcionario_operacional, 'Quiz: Emergências', 
         'Em caso de incêndio, qual deve ser sua primeira ação?',
         '["Tentar apagar o fogo", "Acionar o alarme de emergência", "Buscar seus pertences", "Ligar para a família"]',
         1, 'A primeira ação deve ser acionar o alarme de emergência para alertar todos sobre o perigo.', 
         35, 2, 1);
    END LOOP;
END $$;

-- Quizzes para Gerentes - Liderança
DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_gerente_lideranca UUID;
BEGIN
    SELECT id INTO trail_gerente_lideranca 
    FROM trails 
    WHERE title = 'Liderança e Gestão de Equipes';
    
    -- Quiz para "Estilos de Liderança"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_gerente_lideranca 
        AND title = 'Estilos de Liderança'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_gerente_lideranca, 'Quiz: Estilos de Liderança', 
         'Qual estilo de liderança é mais adequado para uma equipe experiente e motivada?',
         '["Autocrático", "Democrático", "Delegativo", "Paternalista"]',
         2, 'O estilo delegativo é ideal para equipes experientes e motivadas, pois permite autonomia e desenvolvimento.', 
         50, 3, 1);
    END LOOP;
    
    -- Quiz para "Motivação e Engajamento"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_gerente_lideranca 
        AND title = 'Motivação e Engajamento'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_gerente_lideranca, 'Quiz: Motivação', 
         'Segundo a teoria de Maslow, qual necessidade deve ser atendida primeiro?',
         '["Autorrealização", "Estima", "Fisiológicas", "Segurança"]',
         2, 'As necessidades fisiológicas (alimentação, sono, abrigo) são a base da pirâmide de Maslow.', 
         55, 3, 1);
    END LOOP;
    
    -- Quiz para "Feedback e Desenvolvimento"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_gerente_lideranca 
        AND title = 'Feedback e Desenvolvimento'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_gerente_lideranca, 'Quiz: Feedback', 
         'Qual é a característica mais importante de um feedback efetivo?',
         '["Ser dado publicamente", "Ser específico e construtivo", "Focar apenas nos pontos negativos", "Ser dado apenas anualmente"]',
         1, 'Feedback efetivo deve ser específico, construtivo e focado em comportamentos observáveis.', 
         60, 3, 1);
    END LOOP;
END $$;

-- Quizzes para Caixas - Operações
DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_caixa_operacoes UUID;
BEGIN
    SELECT id INTO trail_caixa_operacoes 
    FROM trails 
    WHERE title = 'Operações de Caixa e Pagamentos';
    
    -- Quiz para "Abertura e Fechamento de Caixa"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_caixa_operacoes 
        AND title = 'Abertura e Fechamento de Caixa'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_caixa_operacoes, 'Quiz: Abertura de Caixa', 
         'O que deve ser verificado primeiro na abertura do caixa?',
         '["Funcionamento da impressora", "Valor do fundo de caixa", "Limpeza do terminal", "Horário de funcionamento"]',
         1, 'O valor do fundo de caixa deve ser conferido primeiro para garantir que está correto para iniciar as operações.', 
         35, 2, 1);
    END LOOP;
    
    -- Quiz para "Formas de Pagamento"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_caixa_operacoes 
        AND title = 'Formas de Pagamento'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_caixa_operacoes, 'Quiz: Formas de Pagamento', 
         'Qual informação é obrigatória para processar um pagamento via PIX?',
         '["CPF do cliente", "Chave PIX ou QR Code", "Endereço do cliente", "Telefone do cliente"]',
         1, 'Para processar um PIX é necessário a chave PIX ou QR Code para identificar o destinatário.', 
         40, 2, 1);
    END LOOP;
    
    -- Quiz para "Segurança no Caixa"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_caixa_operacoes 
        AND title = 'Segurança no Caixa'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_caixa_operacoes, 'Quiz: Segurança', 
         'Como identificar uma nota falsa?',
         '["Apenas pela cor", "Textura, marca d\'água e elementos de segurança", "Somente pelo tamanho", "Apenas pelo cheiro"]',
         1, 'Notas verdadeiras possuem textura especial, marca d\'água e diversos elementos de segurança que devem ser verificados.', 
         40, 2, 1);
    END LOOP;
END $$;

-- Quizzes para Trilhas Compartilhadas - Segurança e Compliance
DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_seguranca UUID;
BEGIN
    SELECT id INTO trail_seguranca 
    FROM trails 
    WHERE title = 'Segurança e Compliance Empresarial';
    
    -- Quiz para "LGPD e Proteção de Dados"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_seguranca 
        AND title = 'LGPD e Proteção de Dados'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_seguranca, 'Quiz: LGPD', 
         'Qual é um direito do titular de dados segundo a LGPD?',
         '["Vender seus dados", "Solicitar a exclusão de seus dados", "Alterar dados de terceiros", "Acessar dados de outros clientes"]',
         1, 'A LGPD garante ao titular o direito de solicitar a exclusão de seus dados pessoais.', 
         45, 2, 1);
    END LOOP;
    
    -- Quiz para "Compliance e Ética"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_seguranca 
        AND title = 'Compliance e Ética'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_seguranca, 'Quiz: Ética', 
         'O que caracteriza um conflito de interesses?',
         '["Trabalhar em equipe", "Situação onde interesses pessoais podem influenciar decisões profissionais", "Discordar do supervisor", "Ter opiniões diferentes"]',
         1, 'Conflito de interesses ocorre quando interesses pessoais podem comprometer a imparcialidade nas decisões profissionais.', 
         50, 2, 1);
    END LOOP;
END $$;

DO $$ 
DECLARE 
    lesson_record RECORD;
    trail_cultura UUID;
BEGIN
    SELECT id INTO trail_cultura 
    FROM trails 
    WHERE title = 'Cultura e Valores Organizacionais';
    
    -- Quiz para "Missão, Visão e Valores"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_cultura 
        AND title = 'Missão, Visão e Valores'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_cultura, 'Quiz: Missão e Visão', 
         'Qual é a diferença entre missão e visão da empresa?',
         '["Não há diferença", "Missão é o propósito atual, visão é o futuro desejado", "Visão é mais importante", "Missão muda todo ano"]',
         1, 'A missão define o propósito atual da empresa, enquanto a visão representa onde ela quer chegar no futuro.', 
         25, 1, 1);
    END LOOP;
    
    -- Quiz para "Comportamentos e Atitudes"
    FOR lesson_record IN 
        SELECT id FROM lessons 
        WHERE trail_id = trail_cultura 
        AND title = 'Comportamentos e Atitudes'
    LOOP
        INSERT INTO quizzes (lesson_id, trail_id, title, question, options, correct_answer, explanation, xp_reward, difficulty_level, order_index) VALUES
        (lesson_record.id, trail_cultura, 'Quiz: Comportamentos', 
         'Como você deve demonstrar os valores da empresa no trabalho?',
         '["Apenas em reuniões importantes", "Em todas as ações e decisões diárias", "Somente com clientes", "Apenas quando solicitado"]',
         1, 'Os valores da empresa devem ser demonstrados em todas as ações e decisões do dia a dia de trabalho.', 
         35, 1, 1);
    END LOOP;
END $$;

\echo '✅ Quizzes específicos por grupo criados com sucesso!'

-- =====================================================
-- FUNÇÃO PARA OBTER PROGRESSO DA TRILHA
-- =====================================================

-- Função para obter o progresso de uma trilha específica para um usuário
CREATE OR REPLACE FUNCTION get_trail_progress(
    user_id_param UUID,
    trail_id_param UUID
)
RETURNS TABLE(
    progress_percentage DECIMAL,
    completed_lessons INTEGER,
    total_lessons INTEGER,
    is_completed BOOLEAN
) AS $$
DECLARE
    total_lessons_count INTEGER;
    completed_lessons_count INTEGER;
    progress_percent DECIMAL;
    trail_completed BOOLEAN;
BEGIN
    -- Contar total de lições na trilha
    SELECT COUNT(*) INTO total_lessons_count
    FROM lessons
    WHERE trail_id = trail_id_param AND is_active = true;
    
    -- Contar lições completadas pelo usuário
    SELECT COUNT(*) INTO completed_lessons_count
    FROM user_progress up
    JOIN lessons l ON up.lesson_id = l.id
    WHERE up.user_id = user_id_param 
      AND l.trail_id = trail_id_param 
      AND up.progress_type = 'lesson_completed'
      AND up.is_completed = true;
    
    -- Calcular porcentagem de progresso
    IF total_lessons_count > 0 THEN
        progress_percent := (completed_lessons_count::DECIMAL / total_lessons_count::DECIMAL) * 100;
    ELSE
        progress_percent := 0;
    END IF;
    
    -- Verificar se a trilha está completada
    trail_completed := (completed_lessons_count = total_lessons_count AND total_lessons_count > 0);
    
    -- Retornar resultado
    RETURN QUERY SELECT 
        progress_percent,
        completed_lessons_count,
        total_lessons_count,
        trail_completed;
END;
$$ LANGUAGE plpgsql;

\echo '✅ Função get_trail_progress criada com sucesso!'

\echo '✅ Tabelas principais criadas com sucesso!'
\echo '🎉 Banco de dados PET CLASS configurado!'
\echo ''
\echo '📋 Próximos passos:'
\echo '1. Execute o script de políticas RLS (supabase_rls_policies.sql)'
\echo '2. Execute o script de funções (supabase_functions.sql)'
\echo '3. Execute o script de dados de exemplo (supabase_sample_data.sql)'