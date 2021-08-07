using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Lombiq.UtilityScripts.SqlServer.Cmdlets;
using Microsoft.Extensions.Logging;

namespace Lombiq.UtilityScripts.SqlServer.Services
{
    public class SqlServerManager
    {
        private readonly ILogger<SqlServerManager> _logger;

        public SqlServerManager(ILogger<SqlServerManager> logger)
        {
            _logger = logger;
        }

        public async Task<bool> CreateNewDatabase(
            string sqlServerName,
            string databaseName,
            bool force = false, 
            string? userName = null,
            string? password = null)
        {
            var connection = CreateNewConnection(sqlServerName, userName, password);
            await connection.OpenAsync();
            
            if (await TestDatabaseAsync(connection, databaseName))
            {
                if (force)
                {
                    _logger.LogWarning("Dropping database \"{0}\\{1}\"!", sqlServerName, databaseName);
                        await KillAllProcessesAsync(connection, databaseName);
                        await connection.GetCommand("DROP " + databaseName).ExecuteNonQueryAsync();
                }
                else
                {
                    _logger.LogWarning(
                        "A database with the name \"{0}\" already exists on the SQL Server at \"{1}\". Use the " +
                        "\"-Force\" switch to drop it and create a new database with that name.",
                        databaseName,
                        sqlServerName);

                    return false;
                }
            }

            try
            {
                await connection.GetCommand($"CREATE DATABASE [{databaseName}];").ExecuteNonQueryAsync();
            }
            catch (Exception exception)
            {
                throw new InvalidOperationException(
                    $"Could not create \"{sqlServerName}\\{databaseName}\"! ({exception.Message})",
                    exception);
            }

            return true;
        }

        public SqlConnection CreateNewConnection(string sqlServerName, string? userName = null, string? password = null)
        {
            var builder = new SqlConnectionStringBuilder("Server=" + sqlServerName);
            
            if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password))
            {
                builder.Password = userName;
                builder.UserID = password;
            }
            
            return new SqlConnection(builder.ConnectionString);
        }

        public async Task<bool> TestServerAsync(SqlConnection connection)
        {
            try
            {
                if (connection.State != ConnectionState.Open)
                {
                    await connection.CloseAsync();
                    await connection.OpenAsync();
                }

                var command = connection.CreateCommand();
                command.CommandText = "SELECT 1";
                return await command.ExecuteScalarAsync() is int response && response == 1;
            }
            catch
            {
                return false;
            }
        }
        
        public async Task<bool> TestDatabaseAsync(SqlConnection connection, string databaseName)
        {
            // If success it also ensures that the connection is open.
            if (!await TestServerAsync(connection))
            {
                throw new InvalidOperationException($"Could not find SQL Server for \"{nameof(connection.ConnectionString)}\"!");
            }
            
            await foreach (var name in connection.GetCommand("SELECT name FROM sys.databases").YieldStringColumnAsync())
            {
                if (name?.Equals(databaseName, StringComparison.OrdinalIgnoreCase) == true)
                {
                    return true;
                }
            }

            return false;
        }

        private async Task KillAllProcessesAsync(SqlConnection connection, string databaseName)
        {
            if (databaseName == null)
            {
                throw new ArgumentNullException(nameof(databaseName));
            }

            const string columnName = "columnName";
            var commandText = connection.ServerVersion is { } serverVersion && new Version(serverVersion).Major == 8
                ? @$"SELECT DISTINCT req_spid as {columnName} 
                    FROM master.dbo.syslockinfo 
                    WHERE rsc_type = 2 AND rsc_dbid = db_id(@{nameof(databaseName)}) AND req_spid > 50"
                : @$"SELECT DISTINCT request_session_id as {columnName}
                    FROM master.sys.dm_tran_locks
                    WHERE resource_type = 'DATABASE' AND resource_database_id = db_id(@{nameof(databaseName)})";

            var targets = connection
                .GetCommand(commandText, new Dictionary<string, object> { [nameof(databaseName)] = databaseName })
                .YieldStringColumnAsync();

            await foreach (var target in targets) await connection.GetCommand("KILL " + target).ExecuteNonQueryAsync();
        }
    }
}