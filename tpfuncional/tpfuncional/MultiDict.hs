module MultiDict where

import Data.Maybe
import Data.Char
import Data.List


data MultiDict a b = Nil | Entry a b (MultiDict a b) | Multi a (MultiDict a b) (MultiDict a b) deriving Eq

padlength = 5

isNil Nil = True
isNil _ = False

padMD :: (Show a, Show b) => Int -> MultiDict a b -> String
padMD nivel t = initialPad ++ case t of
                    Nil -> ""
                    Entry k v m -> "\n" ++ initialPad ++ " " ++ show k ++": "++ show v ++ comma m ++ padMD nivel m
                    Multi k m1 m2 -> "\n" ++ initialPad ++ " " ++ show k ++": {"++ rec m1 ++ pad (padlength*nivel) ++"}" ++ comma m2 ++ padMD nivel m2
    where levelPad = (padlength*nivel)
          initialPad = pad levelPad
          rec = padMD (nivel+1)
          comma m = if isNil m then "\n" else ","

pad :: Int -> String
pad i = replicate i ' '

instance (Show a, Show b) => Show (MultiDict a b) where
  show x = "{" ++ padMD 0 x ++ "}"

foldMD :: b ->   (a -> c -> b -> b) -> (a -> b -> b -> b) ->  (MultiDict a c) -> b
foldMD cb fe fm = recMD cb (\k v _ r -> fe k v r) (\k _ _ r1 r2 -> fm k r1 r2)
<<<<<<< HEAD:tpfuncional/tpfuncional/MultiDict.hs
=======

--foldMD cb fe fm  Nil = cb
--foldMD cb fe fm  (Entry k v multidicc) = fe k v (foldMD cb fe fm   multidicc)
--foldMD cb fe fm   (Multi k m1 m2) = fm k (foldMD cb fe fm m1) (foldMD cb fe fm  m2)
>>>>>>> 2f3207e684d89b360ee56a4a890febcb52464fcd:tpfuncional/MultiDict.hs

recMD :: b  -> (a -> c -> MultiDict a c -> b -> b) -> (a -> MultiDict a c -> MultiDict a c -> b -> b -> b) -> MultiDict a c -> b
recMD cb fe fm multi = case multi of Nil -> cb
                                     Entry k v m1 -> fe k v m1 (recMD cb fe fm m1)
                                     Multi k m1 m2 -> fm k m1 m2 (recMD cb fe fm m1) (recMD cb fe fm m2)
<<<<<<< HEAD:tpfuncional/tpfuncional/MultiDict.hs
=======

--recMD cb fe fm  Nil = cb
--recMD cb fe fm  (Entry k v multidicc) = fe k v (multidicc) (recMD cb fe fm   multidicc)
--recMD cb fe fm  (Multi k m1 m2) = fm k m1 m2 (recMD cb fe fm m1) (recMD cb fe fm  m2)
>>>>>>> 2f3207e684d89b360ee56a4a890febcb52464fcd:tpfuncional/MultiDict.hs

profundidad :: MultiDict a b -> Integer
profundidad = foldMD 0 (\_ _ r1 -> max 1 r1) (\_ r1 r2 -> max (r1+1) r2)

--Cantidad total de claves definidas en todos los niveles.
tamaño :: MultiDict a b -> Integer
tamaño = foldMD 0 (\_ _ r1 -> r1 + 1) (\_ r1 r2 -> 1 + r1 + r2 )

podarHasta = foldMD
          (\_ _ _ -> Nil)
          (\k v r l p lorig->cortarOSeguir l p $ Entry k v $ r (l-1) p lorig)
          (\k r1 r2 l p lorig ->cortarOSeguir l p $ Multi k (r1 lorig (p-1) lorig) (r2 (l-1) p lorig))
  where cortarOSeguir l p x = if l <= 0 || p <= 0 then Nil else x

-- Poda a lo ancho y en profundidad.
-- El primer argumento es la cantidad máxima de claves que deben quedar en cada nivel.
-- El segundo es la cantidad de niveles.
podar :: Integer -> Integer -> MultiDict a b -> MultiDict a b
podar long prof m = podarHasta m long prof long

--Dado un entero n, define las claves de n en adelante, cada una con su tabla de multiplicar.
--Es decir, el valor asociado a la clave i es un diccionario con las claves de 1 en adelante, donde el valor de la clave j es i*j.
tablas :: Integer -> MultiDict Integer Integer
tablas n = Multi n (tablaDelDesde n 1) (tablas (n + 1))

-- MultiDict de profundidad 1, tabla del n comenzando desde a.
tablaDelDesde :: Integer -> Integer -> MultiDict Integer Integer
tablaDelDesde n a = Entry a (n * a) (tablaDelDesde n (a + 1))

serialize :: (Show a, Show b) => MultiDict a b -> String
serialize =  foldMD 
          "[ ]" 
          (\k v r -> "[" ++ (show k) ++ ": " ++ (show v) ++ ", " ++ r ++ "]" ) 
          (\k r1 r2 -> "[" ++ (show k) ++ ": " ++ r1 ++ ", " ++ r2 ++ "]")

mapMD :: (a->c) -> (b->d) -> MultiDict a b -> MultiDict c d
mapMD f g = foldMD 
                Nil 
                (\k v r1 -> Entry (f k) (g v) r1) 
                (\k r1 r2 ->  Multi (f k) r1 r2)

--Filtra recursivamente mirando las claves de los subdiccionarios.
filterMD :: (a->Bool) -> MultiDict a b -> MultiDict a b
filterMD p = foldMD 
                 Nil 
                 (\k v r -> if p k then Entry k v r else r) 
                 (\k r1 r2 -> if p k then Multi k r1 r2 else r2)

enLexicon :: [String] -> MultiDict String b -> MultiDict String b
enLexicon p m = filterMD (flip elem p) (mapMD convertirAMinuscula id m) 

convertirAMinuscula:: String -> String 
convertirAMinuscula = map toLower
-- convertirAMinuscula = foldr (\c r-> (toLower c) : r) [] 

cadena :: Eq a => b ->  [a] -> MultiDict a b
cadena v = foldr 
               (\c r -> 
                   if ((profundidad r) == 0) then
                       Entry c v r
                   else 
                       Multi c r Nil ) 
               Nil  

--Agrega a un multidiccionario una cadena de claves [c1, ..., cn], una por cada nivel,
--donde el valor asociado a cada clave es un multidiccionario con la clave siguiente, y así sucesivamente hasta
--llegar a la última clave de la lista, cuyo valor es el dato de tipo b pasado como parámetro.
definir :: Eq a => [a] -> b -> MultiDict a b -> MultiDict a b
definir (x:xs) v d = (recMD (\ks -> cadena v ks)
       (\k1 v1 m r (k:ks)-> if k1 == k then armarDic ks k m (cadena v ks) else Entry k1 v1 (r (k:ks)))
       (\k1 m1 m2 r1 r2 (k:ks) -> if k1 == k then armarDic ks k m2 (r1 ks) else Multi k1 m1 (r2 (k:ks)))) d (x:xs)
  where armarDic ks k resto interior = if null ks then Entry k v resto else Multi k interior resto

obtener :: Eq a => [a] -> MultiDict a b -> Maybe b 
obtener xs d = foldMD (const Nothing) fEntry fMulti d xs
  where fEntry k1 v r claves =
            case claves of [] -> Nothing
                           (k:ks) -> if null ks && (k == k1) then 
                                         Just v 
                                     else 
                                         r (k:ks)
        fMulti k1 r1 r2 claves = 
            case claves of [] -> Nothing
                           (k:ks) -> if k == k1 then 
                                         r1 ks 
                                     else 
                                         r2 (k:ks)
