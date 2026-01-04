manager@gmail.com :111: Manager
accountant@gmail.com:111:Accountant
superAdmin@gmail.com:111:SuperAdmin
waiter@gmail.com:111:Waiter
chef@gmail.com:111:Kitchen
client@gmail.com:111:Customer

Reservation.Pending

--Просмотр доступных типов проектов
dotnet new list

-- Создание проекта mvc
dotnet new mvc -n RestoManager
cd RestoManager
dotnet run

-- Установка инструмента dotnet-ef
dotnet tool install --global dotnet-ef --version 9.*

-- Добавление пакетов в проект
-- SQLite
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
-- MSSQL
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
-- для всех
dotnet add package Microsoft.EntityFrameworkCore.Tools

Добавить файл
..\Data\AppDbContext.cs
Добавить модели
..\Models
-- Можно собрать чтобы проверить на наличие ошибок
dotnet build

-- Добавление миграции
dotnet ef migrations add Initial
-- Обновление базы данных
dotnet ef database update

-- Если надо удалить миграцию
--dotnet ef migrations remove
-- Если надо удалить базу данных
--dotnet ef database drop

--- Добавление генератора в проект
dotnet add package Microsoft.EntityFrameworkCore.Design
-- Установка генератора в систему
dotnet tool install --global dotnet-aspnet-codegenerator

-- Примеры создания Контроллера и Видов к нему
-- SQlite
dotnet aspnet-codegenerator controller -name RolesController -m Role -dc AppDbContext --relativeFolderPath Controllers --useDefaultLayout --referenceScriptLibraries -sqlite
-- MSSQL
dotnet aspnet-codegenerator controller -name PaymentsController -m Payment -dc AppDbContext --relativeFolderPath Controllers --useDefaultLayout --referenceScriptLibraries


-- -------------------------------------------------------------------------------
-- Пакет для шифрования пароля Если нужен
dotnet add package BCrypt.Net-Next
-- пример кода
passwordHash = BCrypt.Net.BCrypt.HashPassword(password);


-- Строка подключения
"ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=MyAuthDb;Trusted_Connection=True;MultipleActiveResultSets=true"
  },

-- Пример создания проекта с аутентификацией (из коробки)
dotnet new mvc --auth Individual -n MyFullApp
-- просмотр версии инструмента ef
dotnet ef --version

--Создание моделей по таблицам баз данных
dotnet ef dbcontext scaffold "Data Source=restaurant.db" Microsoft.EntityFrameworkCore.Sqlite --output-dir Models --force


Примечание: Чтобы админ-панель заработала "по полной" с OpenIddict (интерактивный вход), в этот контроллер нужно добавить методы Authorize и интеграцию с SignInManager. Но для запуска и проверки генерации UI вышеприведенного достаточно.

Запустите приложение:
code
Bash
dotnet run
Перейдите по адресу https://localhost:xxxx/Identity/Account/Register.
Вы увидите стандартный UI Identity (Bootstrap), сгенерированный скаффолдингом.
Вы можете зарегистрировать пользователя. Это создаст запись в таблице AspNetUsers SQLite базы auth.db.
Для проверки API токена (OpenIddict) можно использовать Postman:
URL: https://localhost:xxxx/connect/token
Method: POST
Body (x-www-form-urlencoded):
grant_type: client_credentials
client_id: postman
client_secret: postman-secret
Вы получите JWT токен в ответ.
Итог
У вас есть:
SQLite БД с таблицами Identity и OpenIddict.
Сгенерированный UI (Razor Pages) в папке Areas/Identity, который работает на Cookie.
OpenIddict Сервер, готовый выдавать токены.