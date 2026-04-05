import SwiftUI

struct SelectFooterView: View {
    let course: WalkingCourse
    let confirmAction: () -> Void
    let unconfirmAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(course.stepCount) 歩")
                Text("\(course.expectedMinutes) 分")
                let distance = course.distance.formatted(.number.precision(.fractionLength(1)))
                Text("\(distance) km")
                Text("\(course.calories) kcal")
            }
            .font(.title3)
            .bold()
            .padding()
            
            HStack(spacing: 8) {
                PrimaryButton(title: "再検索する", variant: .outline, action: unconfirmAction)
                PrimaryButton(title: "このコース", variant: .primary, action: confirmAction)
                
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct ConfirmFooterView: View {
    let course: WalkingCourse
    let cancelAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(course.stepCount) 歩")
                Text("\(course.expectedMinutes) 分")
                let distance = course.distance.formatted(.number.precision(.fractionLength(1)))
                Text("\(distance) km")
                Text("\(course.calories) kcal")
            }
            .font(.title3)
            .bold()
            .padding()
            
            PrimaryButton(title: "経路を終了", variant: .cancel, action: cancelAction)
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
