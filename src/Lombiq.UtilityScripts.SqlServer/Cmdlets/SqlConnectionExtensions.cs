using System.Collections.Generic;
using System.Data.SqlClient;

namespace Lombiq.UtilityScripts.SqlServer.Cmdlets
{
    public static class SqlConnectionExtensions
    {
        public static SqlCommand GetCommand(
            this SqlConnection connection,
            string commandText,
            IDictionary<string, object>? parameters = null)
        {
            var command = connection.CreateCommand();
            command.CommandText = commandText;

            if (parameters != null)
            {
                foreach (var (name, value) in parameters)
                {
                    command.Parameters.AddWithValue(name, value);
                }
            }
            
            return command;
        }

        public static async IAsyncEnumerable<string> YieldStringColumnAsync(this SqlCommand command, int columnId = 0)
        {
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                yield return reader.GetString(columnId);
            }
        }
    }
}