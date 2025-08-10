-- ecommerce.sql
-- E-Commerce DB schema + sample data + stored procedure
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- Drop tables (order matters for FK constraints)
DROP TABLE IF EXISTS payments, reviews, order_items, orders, addresses, customers, inventory, product_categories, products, categories;

-- Categories (hierarchical)
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  parent_category_id INT NULL,
  description TEXT,
  UNIQUE (name, parent_category_id),
  FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Products
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Junction: product -> category (many-to-many)
CREATE TABLE product_categories (
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Inventory
CREATE TABLE inventory (
  product_id INT PRIMARY KEY,
  stock_qty INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
  last_restocked TIMESTAMP NULL,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Customers
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- Addresses
CREATE TABLE addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(50),
  country VARCHAR(100),
  address_type ENUM('shipping','billing') DEFAULT 'shipping',
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Orders (header)
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  shipping_address_id INT,
  billing_address_id INT,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('cart','placed','processing','shipped','delivered','cancelled','returned') DEFAULT 'placed',
  subtotal DECIMAL(10,2) DEFAULT 0.00,
  tax DECIMAL(10,2) DEFAULT 0.00,
  shipping_fee DECIMAL(10,2) DEFAULT 0.00,
  total DECIMAL(10,2) DEFAULT 0.00,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id) ON DELETE SET NULL,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Order items (order <-> products with attributes)
CREATE TABLE order_items (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  price_at_purchase DECIMAL(10,2) NOT NULL CHECK (price_at_purchase >= 0),
  line_total DECIMAL(12,2) AS (quantity * price_at_purchase) STORED,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Payments
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  payment_method ENUM('card','paypal','bank_transfer','cash') DEFAULT 'card',
  status ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
  paid_at TIMESTAMP NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Reviews
CREATE TABLE reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  customer_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- SAMPLE DATA (explicit IDs for clarity)

-- Categories
INSERT INTO categories (category_id, name, parent_category_id, description) VALUES
(1, 'Electronics', NULL, 'Electronic devices and gadgets'),
(2, 'Clothing', NULL, 'Apparel and garments'),
(3, 'Accessories', 2, 'Clothing accessories');

-- Products
INSERT INTO products (product_id, sku, name, description, price, active) VALUES
(1, 'ELEC-001','Smartphone X1','Smartphone with 6.5in display',499.99,1),
(2, 'ELEC-002','Wireless Headphones','Noise-cancelling headphones',129.50,1),
(3, 'CLOT-001','T-Shirt Basic','100% cotton t-shirt',12.99,1),
(4, 'CLOT-002','Jeans Slim','Slim fit jeans',39.99,1),
(5, 'ACC-001','Leather Belt','Genuine leather belt',24.50,1),
(6, 'ELEC-003','Portable Charger','10000mAh power bank',19.99,1),
(7, 'ELEC-004','Smartwatch S','Smartwatch with heart rate',149.00,1),
(8, 'ACC-002','Sunglasses','UV protection sunglasses',29.99,1);

-- Product categories
INSERT INTO product_categories (product_id, category_id) VALUES
(1,1),(2,1),(6,1),(7,1),
(3,2),(4,2),
(5,3),(8,3);

-- Inventory
INSERT INTO inventory (product_id, stock_qty, last_restocked) VALUES
(1, 50, NOW()),
(2, 120, NOW()),
(3, 200, NOW()),
(4, 80, NOW()),
(5, 150, NOW()),
(6, 300, NOW()),
(7, 40, NOW()),
(8, 90, NOW());

-- Customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
(1, 'John', 'Doe', 'john@example.com', '123456789'),
(2, 'Mary', 'Smith', 'mary@example.com', '098765432'),
(3, 'Kofi', 'Niyonkuru', 'kofi@example.com', '078912345');

-- Addresses
INSERT INTO addresses (address_id, customer_id, address_line1, city, state, postal_code, country, address_type) VALUES
(1, 1, '123 Main St', 'Kigali', 'Kigali', '00001', 'Rwanda', 'shipping'),
(2, 1, '123 Main St', 'Kigali', 'Kigali', '00001', 'Rwanda', 'billing'),
(3, 2, '45 Market Rd', 'Kigali', 'Kigali', '00002', 'Rwanda', 'shipping'),
(4, 3, '78 Hill Ave', 'Kigali', 'Kigali', '00003', 'Rwanda', 'shipping');

-- Orders
INSERT INTO orders (order_id, customer_id, shipping_address_id, billing_address_id, order_date, status, subtotal, tax, shipping_fee, total) VALUES
(1, 1, 1, 2, '2025-07-01 10:00:00', 'delivered', 629.48, 20.00, 5.00, 654.48),
(2, 2, 3, NULL, '2025-07-05 14:30:00', 'processing', 52.98, 0.00, 5.00, 57.98);

-- Order items (note price_at_purchase should match product price at the sale)
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, price_at_purchase) VALUES
(1, 1, 1, 1, 499.99),
(2, 1, 2, 1, 129.50),
(3, 2, 3, 2, 12.99);

-- Payments
INSERT INTO payments (payment_id, order_id, amount, payment_method, status, paid_at) VALUES
(1, 1, 654.48, 'card', 'completed', '2025-07-01 10:05:00');

-- Reviews
INSERT INTO reviews (review_id, product_id, customer_id, rating, title, body, approved) VALUES
(1, 1, 1, 5, 'Great phone', 'Battery life is excellent', TRUE),
(2, 3, 2, 4, 'Good t-shirt', 'Comfortable and fits well', TRUE);

-- Stored procedure: recalc order totals from order_items
DELIMITER $$
CREATE PROCEDURE sp_calculate_order_total(IN in_order_id INT)
BEGIN
  DECLARE v_subtotal DECIMAL(10,2);
  SELECT IFNULL(SUM(quantity * price_at_purchase), 0.00) INTO v_subtotal
  FROM order_items
  WHERE order_id = in_order_id;

  UPDATE orders
  SET subtotal = v_subtotal,
      total = v_subtotal + COALESCE(tax, 0.00) + COALESCE(shipping_fee, 0.00)
  WHERE order_id = in_order_id;
END $$
DELIMITER ;

-- End of script

