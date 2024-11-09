CREATE PROCEDURE ValidateSelectQuery
    @query NVARCHAR(MAX)
AS
BEGIN
    DECLARE @selectIndex INT, @fromIndex INT, @whereIndex INT;
    DECLARE @columnsName NVARCHAR(MAX), @tableName NVARCHAR(100), @conditions NVARCHAR(MAX);

    -- Find Index of SELECT, FROM, and WHERE keywords
    SET @selectIndex = CHARINDEX('SELECT', @query);
    SET @fromIndex = CHARINDEX('FROM', @query);
    SET @whereIndex = CHARINDEX('WHERE', @query);

    -- Check basic structure: SELECT must come before FROM and FROM before WHERE
    IF @selectIndex = 0 OR @fromIndex = 0 OR @fromIndex < @selectIndex
    BEGIN
        PRINT 'query should be valid ,Invalid query structure.';
        RETURN;
    END

    -- Find column list, table name, and conditions
    SET @columnsName = SUBSTRING(@query, @selectIndex + 6, @fromIndex - @selectIndex - 6);
    SET @tableName = SUBSTRING(@query, @fromIndex + 5, CASE WHEN @whereIndex > 0 THEN @whereIndex - @fromIndex - 5 ELSE LEN(@query) END);
    SET @conditions = CASE WHEN @whereIndex > 0 THEN SUBSTRING(@query, @whereIndex + 5, LEN(@query)) ELSE '' END;

    -- Remove whitespaces for easier processing
    SET @columnsName = LTRIM(RTRIM(REPLACE(@columnsName, ' ', '')));
    SET @tableName = LTRIM(RTRIM(REPLACE(@tableName, ' ', '')));
    SET @conditions = LTRIM(RTRIM(@conditions));

    -- Step 1: Validate columns alternation between INT and VARCHAR
    DECLARE @columnList TABLE (ColumnName NVARCHAR(100), ColumnType NVARCHAR(10));
    DECLARE @currentIndex INT = 1, @nextComma INT, @column NVARCHAR(100), @expectedType NVARCHAR(10);
    SET @expectedType = 'INT';

    WHILE @currentIndex > 0
    BEGIN
        SET @nextComma = CHARINDEX(',', @columnsName, @currentIndex);
        SET @column = CASE WHEN @nextComma > 0 THEN SUBSTRING(@columnsName, @currentIndex, @nextComma - @currentIndex)
                           ELSE SUBSTRING(@columnsName, @currentIndex, LEN(@columnsName) - @currentIndex + 1) END;
        
        -- Insert column and type (assume alternating pattern)
        INSERT INTO @columnList VALUES (@column, @expectedType);

        -- Alternate expected type
        SET @expectedType = CASE WHEN @expectedType = 'INT' THEN 'VARCHAR' ELSE 'INT' END;

        -- Move to next Index
        SET @currentIndex = CASE WHEN @nextComma > 0 THEN @nextComma + 1 ELSE 0 END;
    END

    -- Step 2: Validate WHERE conditions based on @columnList types
    IF @whereIndex > 0 AND LEN(@conditions) > 0
    BEGIN
        DECLARE @condition NVARCHAR(100), @operator NVARCHAR(10), @value NVARCHAR(100);
        DECLARE @condPos INT = 1, @nextAndOr INT, @error NVARCHAR(200);

        WHILE @condPos > 0
        BEGIN
            SET @nextAndOr = PATINDEX('% AND %', @conditions + ' AND ', @condPos);

            SET @condition = CASE WHEN @nextAndOr > 0 THEN SUBSTRING(@conditions, @condPos, @nextAndOr - @condPos)
                                  ELSE SUBSTRING(@conditions, @condPos, LEN(@conditions) - @condPos + 1) END;

            -- Extract column, operator, and value
            SET @operator = CASE WHEN CHARINDEX('=', @condition) > 0 THEN '='
                                 WHEN CHARINDEX('!=', @condition) > 0 THEN '!='
                                 ELSE NULL END;

            IF @operator IS NULL
            BEGIN
                PRINT 'Invalid operator in WHERE clause. clause should be valid';
                RETURN;
            END

            DECLARE @colName NVARCHAR(100), @colValue NVARCHAR(100);
            SET @colName = LTRIM(RTRIM(LEFT(@condition, CHARINDEX(@operator, @condition) - 1)));
            SET @colValue = LTRIM(RTRIM(SUBSTRING(@condition, CHARINDEX(@operator, @condition) + LEN(@operator), LEN(@condition))));

            -- Check column type and Print and Return  if in valid
            DECLARE @type NVARCHAR(10);
            SELECT @type = ColumnType FROM @columnList WHERE ColumnName = @colName;

            IF @type IS NULL
            BEGIN
                PRINT 'column name should be valid . Unknown column in WHERE clause: ' + @colName;
                RETURN;
            END

            -- Print and Return  Check if the value matches the expected type 
            IF @type = 'INT' AND ISNUMERIC(@colValue) = 0
            BEGIN
                PRINT 'Invalid integer value for column ' + @colName + ' in WHERE clause.';
                RETURN;
            END
            ELSE IF @type = 'VARCHAR' AND (@colValue NOT LIKE '''%''')
            BEGIN
                PRINT 'Invalid string value for column ' + @colName + ' in WHERE clause.';
                RETURN;
            END

            -- Move to next condition
            SET @condPos = CASE WHEN @nextAndOr > 0 THEN @nextAndOr + 5 ELSE 0 END;
        END
    END

    PRINT 'Query is valid.'
END;
