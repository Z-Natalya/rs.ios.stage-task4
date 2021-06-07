import Foundation

final class CallStation {
    var callsDict: Dictionary<CallID, Call> = [:]
    var currentCallsDict: Dictionary<User, Call> = [:]
    var userDataSet: Set<User> = []
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) { }
}

extension CallStation: Station {
    func users() -> [User] {
        return Array(userDataSet)
    }
    
    func add(user: User) {
        if (!userDataSet.contains(user)) { userDataSet.insert(user) }
    }
    
    func remove(user: User) {
        if (userDataSet.contains(user)) { userDataSet.remove(user) }
        let call = currentCall(user: user)
        if (call != nil )
        {
            _ = makeErrorCall(incUser: call!.incomingUser, outUser: call!.outgoingUser, ID: call!.id, extra: true)
        }
    }
    
    func execute(action: CallAction) -> CallID? {
        let ID = UUID()
        switch action {
        case let .start(from: incUser, to: outUser):
            if (isAvailable(user: incUser))
            {
                if (!isAvailable(user: outUser))
                {
                    let callError = makeErrorCall(incUser: incUser, outUser: outUser, ID: ID, extra: false)
                    return callError.id
                }
                if (isBusy(userBusy: incUser) || isBusy(userBusy: outUser))
                {
                    let callBusy = makeBusyCall(incUser: incUser, outUser: outUser, ID: ID)
                    return callBusy.id
                }
                let call = makeStartCall(incUser: incUser, outUser: outUser, ID: ID)
                return call.id
            }
        case let .answer(from: user):
            let tuple = whoIsCalling(userWho: user)
            if (tuple == (nil, nil)) { return nil }
            let call = currentCall(user: user)
            if (call != nil)
            {
                let callAnswer = makeAnswerCall(incUser: tuple.0!, outUser: tuple.1!, ID: call!.id)
                return callAnswer.id
            }
        case let .end(from: user):
            let call = currentCall(user: user)
            if (call != nil)
            {
                if (call!.status == .talk)
                {
                    let endCall = makeEndCall(incUser: call!.incomingUser, outUser: call!.outgoingUser, ID: call!.id)
                    return endCall.id
                }
                else
                {
                    let cancelCall = makeCancelCall(incUser: call!.incomingUser, outUser: call!.outgoingUser, ID: call!.id)
                    return cancelCall.id
                }
            }
        }
        return nil
    }
    
    func calls() -> [Call] {
        return Array(callsDict.values)
    }
    
    func calls(user: User) -> [Call] {
        let allCalls = calls()
        var userCalls: Array<Call> = []
        for call in allCalls
        {
            if (user == call.incomingUser || user == call.outgoingUser)
            {
                userCalls.append(call)
            }
        }
        return userCalls
    }
    
    func call(id: CallID) -> Call? {
        return callsDict[id]
    }
    
    func currentCall(user: User) -> Call? {
        return currentCallsDict[user]
    }
    
    func makeErrorCall(incUser: User, outUser: User, ID: CallID, extra: Bool) -> Call {
        let callError = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .ended(reason: .error))
        callsDict[ID] = callError
        if (extra)
        {
            currentCallsDict[incUser] = nil
            currentCallsDict[outUser] = nil
        }
        return callError
    }
    
    func makeBusyCall(incUser: User, outUser: User, ID: CallID) -> Call {
        let callBusy = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .ended(reason: .userBusy))
        callsDict[ID] = callBusy
        return callBusy
    }
    
    func makeStartCall(incUser: User, outUser: User, ID: CallID) -> Call {
        let callStart = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .calling)
        callsDict[ID] = callStart
        currentCallsDict[incUser] = callStart
        currentCallsDict[outUser] = callStart
        return callStart
    }
    
    func makeAnswerCall(incUser: User, outUser: User, ID: CallID) -> Call {
        let callAnswer = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .talk)
        callsDict[ID] = callAnswer
        currentCallsDict[incUser] = callAnswer
        currentCallsDict[outUser] = callAnswer
        return callAnswer
    }
    
    func makeEndCall(incUser: User, outUser: User, ID: CallID) -> Call {
        let callEnd = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .ended(reason: .end))
        callsDict[ID] = callEnd
        currentCallsDict[incUser] = nil
        currentCallsDict[outUser] = nil
        return callEnd
    }
    
    func makeCancelCall(incUser: User, outUser: User, ID: CallID) -> Call {
        let callEnd = Call(id: ID, incomingUser: incUser, outgoingUser: outUser, status: .ended(reason: .cancel))
        callsDict[ID] = callEnd
        currentCallsDict[incUser] = nil
        currentCallsDict[outUser] = nil
        return callEnd
    }
    
    func isAvailable(user: User) -> Bool {
        if (userDataSet.contains(user)) { return true }
        return false
    }
    
    func isBusy(userBusy: User) -> Bool {
        let call = currentCall(user: userBusy)
        if (call != nil) { return true }
        return false
    }
    
    func whoIsCalling(userWho: User) -> (User?, User?) {
        var tuple: (User? , User?) = (nil, nil)
        let call = currentCall(user: userWho)
        if (call == nil) { return tuple }
        if (call?.status == .calling)
        {
            let incUser = call!.incomingUser
            let outUser = call!.outgoingUser
            if (userWho == incUser) { tuple = (outUser, incUser) }
            if (userWho == outUser) { tuple = (incUser, outUser) }
        }
        return tuple
    }
}
