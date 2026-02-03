import SwiftUI

struct CountryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCountry: Country
    @State private var searchText = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.allCountries
        } else {
            return Country.allCountries.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) || 
                $0.dialCode.contains(searchText) ||
                $0.isoCode.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by country or code", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    List {
                        ForEach(filteredCountries) { country in
                            Button(action: {
                                selectedCountry = country
                                dismiss()
                            }) {
                                HStack(spacing: 15) {
                                    Text(country.flag)
                                        .font(.title2)
                                    
                                    Text(country.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(country.dialCode)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CountryPickerView(selectedCountry: .constant(Country.allCountries.first(where: { $0.isoCode == "SA" })!))
}
