import SwiftUI

struct DataTableView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject var schemaService: SchemaService
    @State private var selectedTable: SchemaTable?
    @State private var viewMode: ViewMode = .tablesList
    
    enum ViewMode {
        case tablesList
        case tableData(SchemaTable)
        case tableSchema(SchemaTable)
    }
    
    var body: some View {
        Group {
            switch viewMode {
            case .tablesList:
                TablesListView()
            case .tableData(let table):
                TableDataDetailView(table: table)
            case .tableSchema(let table):
                TableSchemaDetailView(table: table)
            }
        }
    }
    
    @ViewBuilder
    private func TablesListView() -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Таблицы данных")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let schema = schemaService.currentSchema {
                    Text("\(schema.tables.count) таблиц")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            
            Divider()
            
            // Tables list
            if let schema = schemaService.currentSchema {
                TableListView(
                    tables: schema.tables,
                    onViewSchema: { table in
                        selectedTable = table
                        viewMode = .tableSchema(table)
                    },
                    onViewData: { table in
                        print("🔘 DataTableView: onViewData called for table: \(table.name)")
                        selectedTable = table
                        viewMode = .tableData(table)
                        print("🔘 DataTableView: About to call dataService.fetchRecords")
                        dataService.fetchRecords(for: table)
                    },
                    onAddRecord: { table in
                        selectedTable = table
                        viewMode = .tableData(table)
                    }
                )
            } else {
                EmptySchemaView()
            }
        }
    }
    
    @ViewBuilder
    private func TableDataDetailView(table: SchemaTable) -> some View {
        VStack(spacing: 0) {
            // Back button and table info
            HStack {
                Button(action: {
                    viewMode = .tablesList
                    selectedTable = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Назад к таблицам")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Table data view
            TableDataView(table: table, dataService: dataService)
        }
    }
    
    @ViewBuilder
    private func TableSchemaDetailView(table: SchemaTable) -> some View {
        VStack(spacing: 0) {
            // Back button and table info
            HStack {
                Button(action: {
                    viewMode = .tablesList
                    selectedTable = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Назад к таблицам")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Schema view
            TableSchemaView(table: table)
        }
    }
}

struct EmptySchemaView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "table")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Нет схемы данных")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Загрузите схему данных для просмотра таблиц")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
