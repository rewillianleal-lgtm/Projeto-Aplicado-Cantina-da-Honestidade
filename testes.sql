-- ============================================================
-- testes.sql
-- Projeto Aplicado II - CONFIA+ / Cantina da Honestidade
-- Testes do banco de dados MySQL
--
-- Este arquivo contém apenas dados fictícios e comandos de teste.
-- O arquivo banco.sql contém a estrutura oficial do banco.
-- ============================================================

USE confia_plus;

-- ============================================================
-- 1. LIMPEZA DOS DADOS DE TESTE
-- ============================================================
-- Executar esta parte somente se quiser zerar os dados de teste.
-- A ordem respeita as chaves estrangeiras.

DELETE FROM notificacao;
DELETE FROM movimentacao;
DELETE FROM item_compra;
DELETE FROM compra;
DELETE FROM carteira;
DELETE FROM produto;
DELETE FROM usuario;

-- ============================================================
-- 2. CADASTRO DE USUÁRIOS
-- ============================================================

INSERT INTO usuario
(nome, matricula, email, CPF, senha_hash, pin_pagamento, perfil, status)
VALUES
('Renan Teste', 'TEST001', 'renan.teste@exemplo.com', '11111111111',
 'hash_senha_teste_01', '1234', 'CLIENTE', 'ATIVO'),

('Carlos Operador', 'TEST002', 'carlos.operador@exemplo.com', '22222222222',
 'hash_senha_teste_02', '5678', 'OPERADOR', 'ATIVO'),

('Admin Teste', 'TEST003', 'admin.teste@exemplo.com', '33333333333',
 'hash_senha_teste_03', '9012', 'ADMINISTRADOR', 'ATIVO');

-- Conferência dos usuários
SELECT * FROM usuario;

-- ============================================================
-- 3. TESTE DA RELAÇÃO USUARIO -> CARTEIRA
--    Cardinalidade: 1 : 0..1
-- ============================================================
-- Somente o usuário que será utilizado como cliente recebe carteira.
-- A coluna id_usuario é UNIQUE, permitindo no máximo uma carteira
-- para cada usuário.

INSERT INTO carteira
(id_usuario, saldo)
VALUES
(1, 0.00);

SELECT * FROM carteira;

-- Conferência do usuário e sua carteira
SELECT
    u.id_usuario,
    u.nome,
    u.perfil,
    c.id_carteira,
    c.saldo
FROM usuario u
LEFT JOIN carteira c
    ON c.id_usuario = u.id_usuario;

-- ============================================================
-- 4. CADASTRO DE PRODUTOS
-- ============================================================

INSERT INTO produto
(nome, descricao, preco, quantidade_estoque, disponibilidade, qr_code)
VALUES
('Água Mineral', 'Garrafa de água mineral 500ml', 3.00, 20, 'DISPONIVEL',
 'QR-AGUA-001'),

('Refrigerante', 'Refrigerante lata 350ml', 5.00, 15, 'DISPONIVEL',
 'QR-REFRI-001'),

('Salgado', 'Salgado assado', 6.50, 10, 'DISPONIVEL',
 'QR-SALGADO-001');

SELECT * FROM produto;

-- ============================================================
-- 5. TESTE DE CONSULTA DE PRODUTO PELO QR CODE
-- ============================================================
-- Simula a identificação de um produto através do QR Code.

SELECT
    id_produto,
    nome,
    descricao,
    preco,
    quantidade_estoque,
    disponibilidade,
    qr_code
FROM produto
WHERE qr_code = 'QR-AGUA-001';

-- ============================================================
-- 6. TESTE DE RECARGA DA CARTEIRA
-- ============================================================
-- Simula uma recarga de R$ 50,00 utilizando DINHEIRO.
-- A movimentação registra a operação.

START TRANSACTION;

UPDATE carteira
SET saldo = saldo + 50.00
WHERE id_usuario = 1;

INSERT INTO movimentacao
(id_carteira, id_usuario_resp, id_compra, tipo, forma_pagamento, valor, descricao)
VALUES
(1, 2, NULL, 'RECARGA', 'DINHEIRO', 50.00,
 'Recarga de teste da carteira');

COMMIT;

-- Conferência do saldo após a recarga
SELECT
    id_carteira,
    id_usuario,
    saldo
FROM carteira
WHERE id_usuario = 1;

-- Conferência da movimentação
SELECT * FROM movimentacao;

-- ============================================================
-- 7. TESTE DE COMPRA
-- ============================================================
-- Simula uma compra realizada pelo cliente.
-- O pagamento da compra é feito utilizando o saldo da carteira.

START TRANSACTION;

-- Criação da compra
INSERT INTO compra
(id_usuario, valor_total)
VALUES
(1, 8.00);

-- Guarda o ID da compra criada
SET @id_compra_teste = LAST_INSERT_ID();

-- Adiciona os itens da compra
INSERT INTO item_compra
(id_compra, id_produto, quantidade, preco_unitario, subtotal)
VALUES
(@id_compra_teste, 1, 1, 3.00, 3.00),
(@id_compra_teste, 2, 1, 5.00, 5.00);

-- Atualiza o estoque
UPDATE produto
SET quantidade_estoque = quantidade_estoque - 1
WHERE id_produto = 1;

UPDATE produto
SET quantidade_estoque = quantidade_estoque - 1
WHERE id_produto = 2;

-- Desconta o valor da compra da carteira
UPDATE carteira
SET saldo = saldo - 8.00
WHERE id_usuario = 1
  AND saldo >= 8.00;

-- Registra a movimentação da compra.
-- SALDO representa que a compra foi paga utilizando a carteira.

INSERT INTO movimentacao
(id_carteira, id_usuario_resp, id_compra, tipo, forma_pagamento, valor, descricao)
VALUES
(1, 2, @id_compra_teste, 'COMPRA', 'SALDO', 8.00,
 'Compra de teste paga com saldo da carteira');

COMMIT;

-- ============================================================
-- 8. CONFERÊNCIA DA COMPRA
-- ============================================================

SELECT * FROM compra;

SELECT
    ic.id_item_compra,
    ic.id_compra,
    p.nome AS produto,
    ic.quantidade,
    ic.preco_unitario,
    ic.subtotal
FROM item_compra ic
INNER JOIN produto p
    ON p.id_produto = ic.id_produto
WHERE ic.id_compra = @id_compra_teste;

-- ============================================================
-- 9. CONFERÊNCIA DA MOVIMENTAÇÃO RELACIONADA À COMPRA
-- ============================================================

SELECT
    m.id_movimentacao,
    m.id_carteira,
    m.id_compra,
    m.tipo,
    m.forma_pagamento,
    m.valor,
    m.data_hora,
    m.descricao
FROM movimentacao m
WHERE m.id_compra = @id_compra_teste;

-- ============================================================
-- 10. CONFERÊNCIA DO ESTOQUE APÓS A COMPRA
-- ============================================================

SELECT
    id_produto,
    nome,
    quantidade_estoque,
    disponibilidade
FROM produto;

-- ============================================================
-- 11. CONFERÊNCIA DO SALDO APÓS A COMPRA
-- ============================================================

SELECT
    u.nome,
    c.saldo
FROM usuario u
INNER JOIN carteira c
    ON c.id_usuario = u.id_usuario
WHERE u.id_usuario = 1;

-- ============================================================
-- 12. TESTE DE NOTIFICAÇÃO
-- ============================================================
-- Simula uma notificação vinculada à movimentação da compra.

INSERT INTO notificacao
(id_usuario, id_movimentacao, mensagem)
VALUES
(1, 
 (SELECT id_movimentacao
  FROM movimentacao
  WHERE id_compra = @id_compra_teste
  ORDER BY id_movimentacao DESC
  LIMIT 1),
 'Compra de teste realizada com sucesso.');

SELECT * FROM notificacao;

-- ============================================================
-- 13. TESTE DO HISTÓRICO DO CLIENTE
-- ============================================================
-- Consulta as movimentações da carteira do cliente.

SELECT
    m.id_movimentacao,
    m.tipo,
    m.forma_pagamento,
    m.valor,
    m.data_hora,
    m.descricao
FROM movimentacao m
WHERE m.id_carteira = 1
ORDER BY m.data_hora DESC;

-- ============================================================
-- 14. TESTE DO HISTÓRICO DE COMPRAS
-- ============================================================

SELECT
    c.id_compra,
    u.nome AS cliente,
    c.valor_total,
    c.data_hora
FROM compra c
INNER JOIN usuario u
    ON u.id_usuario = c.id_usuario
ORDER BY c.data_hora DESC;

-- ============================================================
-- 15. TESTE COMPLETO DA COMPRA
-- ============================================================
-- Mostra cliente, compra, produtos e valores.

SELECT
    c.id_compra,
    u.nome AS cliente,
    p.nome AS produto,
    ic.quantidade,
    ic.preco_unitario,
    ic.subtotal,
    c.valor_total,
    c.data_hora
FROM compra c
INNER JOIN usuario u
    ON u.id_usuario = c.id_usuario
INNER JOIN item_compra ic
    ON ic.id_compra = c.id_compra
INNER JOIN produto p
    ON p.id_produto = ic.id_produto
WHERE c.id_compra = @id_compra_teste;

-- ============================================================
-- 16. TESTE DE SALDO INSUFICIENTE
-- ============================================================
-- Apenas consulta. Não altera os dados.
-- Verifica se o saldo atual é suficiente para uma compra hipotética
-- de R$ 100,00.

SELECT
    id_usuario,
    saldo,
    CASE
        WHEN saldo >= 100.00 THEN 'SALDO SUFICIENTE'
        ELSE 'SALDO INSUFICIENTE'
    END AS resultado
FROM carteira
WHERE id_usuario = 1;

-- ============================================================
-- 17. RESUMO FINAL DOS DADOS
-- ============================================================

SELECT 'USUARIOS' AS tabela, COUNT(*) AS quantidade FROM usuario
UNION ALL
SELECT 'CARTEIRAS', COUNT(*) FROM carteira
UNION ALL
SELECT 'PRODUTOS', COUNT(*) FROM produto
UNION ALL
SELECT 'COMPRAS', COUNT(*) FROM compra
UNION ALL
SELECT 'ITENS_COMPRA', COUNT(*) FROM item_compra
UNION ALL
SELECT 'MOVIMENTACOES', COUNT(*) FROM movimentacao
UNION ALL
SELECT 'NOTIFICACOES', COUNT(*) FROM notificacao;

-- ============================================================
-- FIM DOS TESTES
-- ============================================================
