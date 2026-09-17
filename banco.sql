CREATE DATABASE IF NOT EXISTS confia_plus
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE confia_plus;

-- ============================================
-- USUARIO
-- ============================================

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    matricula VARCHAR(30) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    pin_pagamento VARCHAR(255) NOT NULL,
    perfil ENUM('CLIENTE', 'OPERADOR', 'ADMINISTRADOR') NOT NULL DEFAULT 'CLIENTE',
    status BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CARTEIRA
-- ============================================

CREATE TABLE carteira (
    id_carteira INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_carteira_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

-- ============================================
-- PRODUTO
-- ============================================

CREATE TABLE produto (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10,2) NOT NULL,
    quantidade_estoque INT NOT NULL DEFAULT 0,
    disponibilidade BOOLEAN NOT NULL DEFAULT TRUE,

    -- QR Code utilizado para identificar o produto
    qr_code VARCHAR(255) UNIQUE,

    data_cadastro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- COMPRA
-- ============================================

CREATE TABLE compra (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_compra_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario)
);

-- ============================================
-- ITEM DA COMPRA
-- ============================================

CREATE TABLE item_compra (
    id_item_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_item_compra_compra
        FOREIGN KEY (id_compra)
        REFERENCES compra(id_compra),

    CONSTRAINT fk_item_compra_produto
        FOREIGN KEY (id_produto)
        REFERENCES produto(id_produto)
);

-- ============================================
-- MOVIMENTACAO
-- ============================================

CREATE TABLE movimentacao (
    id_movimentacao INT AUTO_INCREMENT PRIMARY KEY,
    id_carteira INT NOT NULL,
    id_usuario_resp INT NULL,
    id_compra INT NULL,
    tipo ENUM('RECARGA', 'COMPRA') NOT NULL,
    forma_pagamento ENUM('PIX', 'DINHEIRO') NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(255),

    CONSTRAINT fk_movimentacao_carteira
        FOREIGN KEY (id_carteira)
        REFERENCES carteira(id_carteira),

    CONSTRAINT fk_movimentacao_usuario_resp
        FOREIGN KEY (id_usuario_resp)
        REFERENCES usuario(id_usuario),

    CONSTRAINT fk_movimentacao_compra
        FOREIGN KEY (id_compra)
        REFERENCES compra(id_compra)
);

-- ============================================
-- NOTIFICACAO
-- ============================================

CREATE TABLE notificacao (
    id_notificacao INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_movimentacao INT NOT NULL,
    mensagem VARCHAR(255) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lida BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_notificacao_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario),

    CONSTRAINT fk_notificacao_movimentacao
        FOREIGN KEY (id_movimentacao)
        REFERENCES movimentacao(id_movimentacao)
);
