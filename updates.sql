USE pastryshop;

CREATE TABLE IF NOT EXISTS suppliers (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(150) NOT NULL,
  empresa     VARCHAR(150),
  telefono    VARCHAR(20),
  email       VARCHAR(150),
  direccion   TEXT,
  ruc         VARCHAR(20),
  activo      TINYINT(1) NOT NULL DEFAULT 1,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS purchases (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  supplier_id INT UNSIGNED NOT NULL,
  user_id     INT UNSIGNED NOT NULL,
  total       DECIMAL(10,2) NOT NULL DEFAULT 0,
  estado      ENUM('pendiente','completada','cancelada') NOT NULL DEFAULT 'completada',
  fecha       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notas       TEXT,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_purchases_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_purchases_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS purchase_items (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_id     INT UNSIGNED NOT NULL,
  product_id      INT UNSIGNED,
  descripcion     VARCHAR(150),
  cantidad        INT UNSIGNED NOT NULL,
  costo_unitario  DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_purchaseitems_purchase FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
  CONSTRAINT fk_purchaseitems_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employee_profiles (
  id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id            INT UNSIGNED NOT NULL UNIQUE,
  cargo              VARCHAR(100),
  fecha_contratacion DATE,
  salario            DECIMAL(10,2),
  horario            VARCHAR(100),
  notas              TEXT,
  CONSTRAINT fk_employee_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS logs (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED,
  accion      VARCHAR(255) NOT NULL,
  modulo      VARCHAR(100) NOT NULL,
  descripcion TEXT,
  ip_address  VARCHAR(50),
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  titulo      VARCHAR(150) NOT NULL,
  mensaje     TEXT NOT NULL,
  leida       TINYINT(1) NOT NULL DEFAULT 0,
  tipo        ENUM('info','alerta','sistema') NOT NULL DEFAULT 'info',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Insert some dummy data
INSERT INTO suppliers (nombre, empresa, telefono, email, direccion, ruc) VALUES 
('Juan Perez', 'Distribuidora Panadera SA', '555-8888', 'ventas@distpanadera.com', 'Av Industrial 123', '20123456789'),
('Maria Gomez', 'Lacteos del Valle', '555-9999', 'contacto@lacteosvalle.com', 'Carretera Norte Km 5', '20987654321');

INSERT INTO employee_profiles (user_id, cargo, fecha_contratacion, salario, horario) VALUES
(2, 'Maestro Pastelero', '2023-01-15', 2500.00, '08:00 - 16:00');
