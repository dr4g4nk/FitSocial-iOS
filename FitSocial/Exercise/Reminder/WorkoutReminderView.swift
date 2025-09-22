//
//  WorkoutReminderView.swift
//  FitSocial
//
//  Created by Dragan Kos on 4. 9. 2025..
//

import SwiftUI

struct WorkoutReminderView: View {
    @Bindable private var vm: WorkoutReminderViewModel

    init(vm: WorkoutReminderViewModel) {
        self.vm = vm
    }

    var body: some View {
        NavigationStack {
            VStack {
                if vm.reminders.isEmpty {
                    ContentUnavailableView(
                        "Nema zakazanih podsetnika",
                        systemImage: "bell.slash.fill"
                    )
                } else {
                    List {
                        ForEach(vm.reminders) { reminder in
                            ReminderRowView(reminder: reminder)
                        }
                        .onDelete(perform: vm.deleteReminder)
                    }.refreshable(action: { vm.loadReminders() })
                }

                Button(action: {
                    vm.showScheduleForm = true
                }) {
                    HStack {
                        Image(systemName: "bell")
                        Text("Novi podsetnik")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()

            }
            .errorBanner(message: $vm.errorMessage)
            .onAppear {
                vm.loadReminders()
            }
            .navigationTitle("Podsetnici za vežbanje")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $vm.showScheduleForm) {
                VStack(spacing: 12) {
                    Text("Novi podsetnik za vežbanje").font(.title)
                    TextField(
                        "Podsetnik...",
                        text: $vm.workoutTitle,
                        axis: .vertical
                    )
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.separator), lineWidth: 0.5)
                    )
                    .lineLimit(1...5)
                    .accessibilityLabel("Podsetnik...")

                    HStack {
                        Text("Tip vežbe")
                        Spacer()
                        Picker("Tip vežbe", selection: $vm.workoutType) {
                            ForEach(ActivityType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type.rawValue)
                            }
                        }.pickerStyle(MenuPickerStyle())
                    }

                    DatePicker(
                        "Datum",
                        selection: $vm.selectedDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Vreme",
                        selection: $vm.reminderTime,
                        displayedComponents: .hourAndMinute
                    )

                    Button(action: vm.scheduleReminder) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Zakaži podsetnik")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .presentationDetents([.medium, .large])
                .padding()
                .onAppear {
                    vm.checkAuthorization()
                }
                .alert(
                    "Pristup odbijen",
                    isPresented: $vm.showPermissionAlert,
                    actions: {
                        SettingsButton(url: URL(string: UIApplication.openNotificationSettingsURLString)) {
                            vm.showPermissionAlert = false
                        }
                        Button("Kasnije") {
                            vm.showScheduleForm = false
                        }
                    },
                    message: { Text(vm.unauthorizeMesssage ?? "") }
                )
            }
            .alert("Podsetnik", isPresented: $vm.showingAlert) {
                Button("OK") {}
            } message: {
                Text(vm.alertMessage)
            }

        }
    }
}

struct ReminderRowView: View {
    let reminder: WorkoutReminder

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading) {
                    Text(reminder.title)
                        .font(.headline)
                    Text(reminder.workoutType)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(reminder.scheduledDate, style: .date)
                        .font(.caption)
                    Text(reminder.scheduledDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            if reminder.scheduledDate > Date() {
                Label("Aktivan", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Istekao", systemImage: "clock.badge.xmark")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 5)
    }
}
