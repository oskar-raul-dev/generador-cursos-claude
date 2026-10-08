CREATE TABLE settlements (
    id          bigserial PRIMARY KEY,
    franchise   text NOT NULL,
    quarter     text NOT NULL,
    amount      numeric(14, 2) NOT NULL CHECK (amount >= 0),
    UNIQUE (franchise, quarter)
);
