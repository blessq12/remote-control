import SwiftUI

struct SidebarView: View {
    @ObservedObject var companyStorage: CompanyStorageService
    let onEditCompany: (Company) -> Void
    @State private var showingAddCompany = false
    @State private var showingEditCompany = false
    @State private var companyToEdit: Company?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Компании")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddCompany = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
            .padding()

            
            Divider()
            
            List(companyStorage.companies) { company in
                CompanyRowView(
                    company: company,
                    isSelected: company.isActive,
                    onTap: {
                        companyStorage.setActiveCompany(company)
                    },
                    onEdit: {
                        companyToEdit = company
                        showingEditCompany = true
                    },
                    onDelete: {
                        companyStorage.deleteCompany(company)
                    }
                )
            }
            .listStyle(SidebarListStyle())
        }
        .popover(isPresented: $showingAddCompany, attachmentAnchor: .point(.center)) {
            AddCompanyView(companyStorage: companyStorage)
                .frame(width: 400)
        }
        .popover(isPresented: $showingEditCompany, attachmentAnchor: .point(.center)) {
            if let companyToEdit = companyToEdit {
                EditCompanyView(companyStorage: companyStorage, company: companyToEdit)
                    .frame(width: 400)
            }
        }
    }
}

struct CompanyRowView: View {
    let company: Company
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingContextMenu = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(company.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Редактировать") {
                onEdit()
            }
            
            Button("Удалить", role: .destructive) {
                // TODO: Добавить удаление компании
                onDelete()
                print("Удаление компании: \(company.name)")
            }
        }
    }
}
