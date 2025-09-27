import SwiftUI

@main
struct RemoteControlApp: App {
    @StateObject private var companyStorage = CompanyStorageService()
    @StateObject private var schemaService = SchemaService()
    @StateObject private var dataService = DataService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(companyStorage)
                .environmentObject(schemaService)
                .environmentObject(dataService)
                .onAppear {
                    // Принудительно активируем приложение при запуске
                    DispatchQueue.main.async {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    @EnvironmentObject var companyStorage: CompanyStorageService
    @EnvironmentObject var schemaService: SchemaService
    @EnvironmentObject var dataService: DataService
    @State private var sidebarVisible = true
    @State private var sidebarWidth: CGFloat = 250
    
    var body: some View {
        HStack(spacing: 0) {
            if sidebarVisible {
                SidebarView(companyStorage: companyStorage, onEditCompany: editCompany)
                    .frame(width: sidebarWidth)
                    .background(Color(NSColor.controlBackgroundColor))
                
                // Resizable divider
                ResizeHandle()
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = sidebarWidth + value.translation.width
                                sidebarWidth = max(150, min(400, newWidth))
                            }
                    )
            }
            
            if let activeCompany = companyStorage.activeCompany {
                DetailView(
                    company: activeCompany,
                    schemaService: schemaService,
                    dataService: dataService,
                    sidebarVisible: $sidebarVisible
                )
            } else {
                WelcomeView(sidebarVisible: $sidebarVisible)
            }
        }
        .onChange(of: companyStorage.activeCompany) { company in
            if let company = company {
                dataService.setCompany(company)
                schemaService.clearSchema()
            } else {
                schemaService.clearSchema()
                dataService.records = []
            }
        }
    }
    
    private func editCompany(_ company: Company) {
        // Теперь логика редактирования перенесена в SidebarView
    }
}

struct DetailView: View {
    let company: Company
    @ObservedObject var schemaService: SchemaService
    @ObservedObject var dataService: DataService
    @Binding var sidebarVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок компании
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(company.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.secondary)
                            Text(company.url)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Connection status indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(connectionStatusColor)
                                    .frame(width: 8, height: 8)
                                Text(connectionStatusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button("Тест соединения") {
                            schemaService.testConnection(to: company)
                        }
                        .buttonStyle(.bordered)
                        .disabled({
                            if case .connecting = schemaService.connectionStatus { return true }
                            return false
                        }())
                        
                        Button("Получить схему данных") {
                            schemaService.fetchSchema(for: company)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(schemaService.isLoading)
                        
                        Button(sidebarVisible ? "Скрыть сайдбар" : "Показать сайдбар") {
                            sidebarVisible.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Контент
            if schemaService.isLoading {
                ProgressView("Загрузка схемы...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = schemaService.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Ошибка загрузки схемы")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if schemaService.currentSchema == nil {
                VStack {
                    Image(systemName: "server.rack")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Схема не загружена")
                        .font(.headline)
                    Text("Проверьте подключение к серверу")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DataTableView(dataService: dataService, schemaService: schemaService)
            }
        }
    }
    
    // MARK: - Connection Status Helpers
    
    private var connectionStatusColor: Color {
        switch schemaService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .failed:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private var connectionStatusText: String {
        switch schemaService.connectionStatus {
        case .connected:
            return "Подключено"
        case .connecting:
            return "Подключение..."
        case .failed(_):
            return "Ошибка"
        case .unknown:
            return "Не проверено"
        }
    }
}

struct WelcomeView: View {
    @Binding var sidebarVisible: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "server.rack")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Remote Control")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Выберите компанию для начала работы")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(sidebarVisible ? "Скрыть сайдбар" : "Показать сайдбар") {
                sidebarVisible.toggle()
            }
            .buttonStyle(.bordered)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ResizeHandle: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 4)
            .background(Color.gray.opacity(0.3))
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
