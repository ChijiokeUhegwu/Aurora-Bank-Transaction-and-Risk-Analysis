-- Setting Relationships between the tables

-- Relationship: cards_data → users_data
ALTER TABLE cards_data
ADD CONSTRAINT FK_cards_users
FOREIGN KEY (client_id)
REFERENCES users_data(id);

-- Relationship: transactions_data → users_data
ALTER TABLE transactions_data
ADD CONSTRAINT FK_transactions_users
FOREIGN KEY (client_id)
REFERENCES users_data(id);

-- Relationship: transactions_data → cards_data
ALTER TABLE transactions_data
ADD CONSTRAINT FK_transactions_cards
FOREIGN KEY (card_id)
REFERENCES cards_data(id);

-- Relationship: transactions_data → mcc_codes
ALTER TABLE transactions_data
ADD CONSTRAINT FK_transactions_mcc
FOREIGN KEY (mcc)
REFERENCES mcc_codes(mcc_id);

-- Ensure referential integrity is enforced and indexes exist on foreign key columns:
CREATE INDEX idx_client_id ON transactions_data(client_id);
CREATE INDEX idx_card_id ON transactions_data(card_id);
CREATE INDEX idx_mcc ON transactions_data(mcc);
