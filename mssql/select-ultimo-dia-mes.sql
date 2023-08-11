SELECT EOMONTH(CONVERT(DATE, getdate()), 0)  AS 'ultimo dia do mes atual';
SELECT EOMONTH(CONVERT(DATE, getdate()), -1) AS 'ultimo dia do mes anterior';
SELECT EOMONTH(CONVERT(DATE, getdate()), +1) AS 'ultimo dia do proximo mes';

-- Fonte: Whatsapp: Autoridade MS SQL Server ~ William

/*
A função `EOMONTH` (End of Month) no Microsoft SQL Server é uma função usada para retornar a data do último dia do mês para uma data fornecida como argumento. Ela é especialmente útil quando você precisa calcular a data final de um mês em particular ou realizar cálculos que envolvam o último dia de um mês.

A sintaxe básica da função `EOMONTH` é a seguinte:

```sql
EOMONTH (start_date [, months_to_add])
```

- `start_date`: A data para a qual você deseja encontrar o último dia do mês.
- `months_to_add`: (Opcional) Um valor inteiro que representa o número de meses a serem adicionados à `start_date` antes de calcular o último dia do mês. Se não for fornecido, o valor padrão é 0.

Exemplo de uso:

```sql
SELECT EOMONTH('2023-08-11') AS LastDayOfMonth;
```

Neste exemplo, a função `EOMONTH` é usada para encontrar o último dia do mês de agosto de 2023, resultando em `'2023-08-31'`.

Outro exemplo com o parâmetro `months_to_add`:

```sql
SELECT EOMONTH('2023-08-11', 2) AS LastDayOfNextMonth;
```

Neste caso, a função `EOMONTH` é usada para encontrar o último dia do mês que está dois meses após agosto de 2023, resultando em `'2023-10-31'`.

A função `EOMONTH` é especialmente útil para cálculos de datas, planejamento financeiro e relatórios que envolvam datas no contexto de um mês. Ela ajuda a evitar a necessidade de calcular manualmente o último dia de um mês, facilitando o desenvolvimento de consultas mais precisas e eficientes.

-- Fonte:https://chat.openai.com/
*/