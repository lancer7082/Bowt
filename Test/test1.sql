DECLARE @Orders TABLE (
	[OrderId] INT PRIMARY KEY,
  [Quantity] INT,
  [Min] INT,
  [Rate] NUMERIC(18, 4)
)

DECLARE @Trades TABLE (
  [TradeId] INT IDENTITY (1,1) PRIMARY KEY,
  [OrderId] INT NOT NULL,
  [Quantity] INT,
  --[QuantityAgg] INT,
  [RowId] INT,
  [FeeRest] NUMERIC(18, 2),
  [Fee] NUMERIC(18, 2)
)  

INSERT @Orders ([OrderId], [Quantity], [Min], [Rate])
VALUES
(1, 20, 50, 3),
(2, 10, 50, 3),
(3, 30, 50, 3),
(4, 40, 50, 2)

INSERT @Trades ([OrderId], [Quantity])
VALUES
(1, 15),
(3, 20),
(1, 5),
(3, 10),
(2, 10),
(4, 10),
(4, 10),
(4, 10),
(4, 10)

IF EXISTS (
  SELECT *
    --T.*, O.[Quantity], O.[Min], O.[Rate], [Commiss] = O.[Quantity] * O.[Rate] 
  FROM (
    SELECT T.[OrderId], [Quantity] = SUM(T.[Quantity])
    FROM @Trades T
    GROUP BY T.[OrderId]
  ) T
  INNER JOIN @Orders O ON O.[OrderId] = T.[OrderId]
  WHERE O.[Quantity] <> T.[Quantity]
) 
  RAISERROR('Error', 16, 1)

SELECT O.*, 
  [Com] = O.[Quantity] * O.[Rate],
  [Com1] = O.[Min],
  [Com2] = CASE WHEN O.[Quantity] * O.[Rate] > O.[Min] THEN O.[Quantity] * O.[Rate] - O.[Min] ELSE 0 END   
FROM @Orders O

SELECT T.*, [RowId] = ROW_NUMBER() OVER (PARTITION BY T.[OrderId] ORDER BY T.[TradeId] DESC)
FROM @Trades T

DECLARE
  @FeeRest NUMERIC(18, 2),
  @Fee NUMERIC(18, 2) = 0

UPDATE T1 SET 
  [RowId] = T.[RowId],
  @FeeRest = 
      CASE
        WHEN T.[RowId] = 1 THEN O.[Quantity] * O.[Rate] - O.[Min]
        ELSE @FeeRest - @Fee
      END,
  @Fee = [Fee] = 
    CASE 
      WHEN @FeeRest > 0 THEN 
        CASE
          WHEN @FeeRest > T.[Quantity] * O.[Rate] THEN T.[Quantity] * O.[Rate]
          ELSE @FeeRest
        END   
    END
FROM (
  SELECT T.[TradeId], T.[Quantity], 
    [RowId] = ROW_NUMBER() OVER (PARTITION BY T.[OrderId] ORDER BY T.[TradeId] DESC)
  FROM @Trades T
) T
INNER JOIN @Trades T1 ON T1.TradeId = T.TradeId
INNER JOIN @Orders O ON O.[OrderId] = T1.[OrderId]
WHERE O.[Quantity] * O.[Rate] > O.[Min]

SELECT T.*, T.[Quantity] * O.[Rate] 
FROM @Trades T
INNER JOIN @Orders O ON O.[OrderId] = T.[OrderId]
ORDER BY T.[OrderId], T.[TradeId]

SELECT T.[TradeId], T.[OrderId], T.[Fee] FROM @Trades T
WHERE T.[Fee] <> 0
UNION
SELECT T.[TradeId], O.[OrderId], O.[Min] 
FROM @Orders O 
OUTER APPLY (
	SELECT TOP 1 T.[TradeId]
  FROM @Trades T 
  WHERE T.[OrderId] = O.[OrderId]
) T   
ORDER BY T.[OrderId], T.[TradeId]

RETURN



  
--SELECT * FROM @Orders
--SELECT * FROM @Trades

 