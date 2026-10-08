-- V2 de mono-inventory (taller 10): la versión siguiente renombra su columna. Solo se aplica si se
-- despliega esa versión (lab.py inventory --rename).
ALTER TABLE inventory RENAME COLUMN stock TO on_hand;
