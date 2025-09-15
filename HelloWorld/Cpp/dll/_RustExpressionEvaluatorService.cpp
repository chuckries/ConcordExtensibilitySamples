#include "stdafx.h"
#include "_RustExpressionEvaluatorService.h"
#include <dia2.h>


HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::EvaluateExpression(
    _In_ Evaluation::DkmInspectionContext* pInspectionContext,
    _In_ DkmWorkList* pWorkList,
    _In_ Evaluation::DkmLanguageExpression* pExpression,
    _In_ CallStack::DkmStackWalkFrame* pStackFrame,
    _In_ IDkmCompletionRoutine<Evaluation::DkmEvaluateExpressionAsyncResult>* pCompletionRoutine
)
{
    if (DkmString::CompareOrdinalIgnoreCase(pExpression->Text(), L"hello") == 0)
    {
        // try to get DIA
        if (pStackFrame->ModuleInstance() != nullptr)
        {
            CComPtr<DkmModule> pModule;
            if (SUCCEEDED(pStackFrame->ModuleInstance()->GetModule(&pModule)))
            {
                CComPtr<IUnknown> pDiaSessionUnk;
                HRESULT hr = pModule->GetSymbolInterface(__uuidof(IDiaSession), &pDiaSessionUnk);

                CComPtr<IDiaSession> pDiaSession;
                hr = pDiaSessionUnk.QueryInterface(&pDiaSession);
            }
        }

        {
            // read and write the current frame info
            UINT64 address = pStackFrame->InstructionAddress()->CPUInstructionPart()->InstructionPointer;

            UINT64 memoryValue = 0;
            UINT32 dwBytesRead = 0;
            DkmProcess* pProcess = pStackFrame->Process();
            HRESULT hr = pProcess->ReadMemory(
                address,
                DkmReadMemoryFlags::None,
                (void*)&memoryValue,
                sizeof(UINT64),
                &dwBytesRead);

            hr = pProcess->WriteMemory(
                address,
                DkmArray<BYTE> { (BYTE*)&memoryValue, sizeof(UINT64) });
        }


        CComPtr<DkmString> pValue;
        HRESULT hr = DkmString::Create(L"from rust ee", &pValue);

        // create a result for this expression
        CComPtr<DkmSuccessEvaluationResult> pEvalResult;
        hr = DkmSuccessEvaluationResult::Create(
            pInspectionContext,
            pStackFrame,
            pExpression->Text(), // name
            pExpression->Text(), // full name
            DkmEvaluationResultFlags::None,
            pValue,
            nullptr,
            nullptr,
            DkmEvaluationResultCategory::Other,
            DkmEvaluationResultAccessType::None,
            DkmEvaluationResultStorageType::None,
            DkmEvaluationResultTypeModifierFlags::None,
            nullptr,
            nullptr,
            nullptr,
            nullptr,
            DkmDataItem::Null(),
            &pEvalResult);


        DkmEvaluateExpressionAsyncResult asyncResult = DkmEvaluateExpressionAsyncResult{
            S_OK,
            pEvalResult
        };

        pCompletionRoutine->OnComplete(asyncResult);
        return S_OK;
    }

    // chain the call down to the fallback EE
    return pInspectionContext->EvaluateExpression(
        pWorkList,
        pExpression,
        pStackFrame,
        pCompletionRoutine
    );
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::GetChildren(
    _In_ Evaluation::DkmEvaluationResult* pResult,
    _In_ DkmWorkList* pWorkList,
    _In_ UINT32 InitialRequestSize,
    _In_ Evaluation::DkmInspectionContext* pInspectionContext,
    _In_ IDkmCompletionRoutine<Evaluation::DkmGetChildrenAsyncResult>* pCompletionRoutine
)
{
    return pResult->GetChildren(
        pWorkList,
        InitialRequestSize,
        pInspectionContext,
        pCompletionRoutine
	);
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::GetFrameLocals(
    _In_ Evaluation::DkmInspectionContext* pInspectionContext,
    _In_ DkmWorkList* pWorkList,
    _In_ CallStack::DkmStackWalkFrame* pStackFrame,
    _In_ IDkmCompletionRoutine<Evaluation::DkmGetFrameLocalsAsyncResult>* pCompletionRoutine
)
{
    return pInspectionContext->GetFrameLocals(
        pWorkList,
        pStackFrame,
        pCompletionRoutine
	);
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::GetFrameArguments(
    _In_ Evaluation::DkmInspectionContext* pInspectionContext,
    _In_ DkmWorkList* pWorkList,
    _In_ CallStack::DkmStackWalkFrame* pFrame,
    _In_ IDkmCompletionRoutine<Evaluation::DkmGetFrameArgumentsAsyncResult>* pCompletionRoutine
)
{
    return pInspectionContext->GetFrameArguments(
        pWorkList,
        pFrame,
        pCompletionRoutine
    );
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::GetItems(
    _In_ Evaluation::DkmEvaluationResultEnumContext* pEnumContext,
    _In_ DkmWorkList* pWorkList,
    _In_ UINT32 StartIndex,
    _In_ UINT32 Count,
    _In_ IDkmCompletionRoutine<Evaluation::DkmEvaluationEnumAsyncResult>* pCompletionRoutine
)
{
    return pEnumContext->GetItems(
        pWorkList,
        StartIndex,
        Count,
        pCompletionRoutine
	);
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::SetValueAsString(
    _In_ Evaluation::DkmEvaluationResult* pResult,
    _In_ DkmString* pValue,
    _In_ UINT32 Timeout,
    _Deref_out_opt_ DkmString** ppErrorText
)
{
    return pResult->SetValueAsString(
        pValue,
        Timeout,
        ppErrorText
    );
}

HRESULT STDMETHODCALLTYPE CRustExpressionEvaluatorService::GetUnderlyingString(
    _In_ Evaluation::DkmEvaluationResult* pResult,
    _Deref_out_opt_ DkmString** ppStringValue
)
{
    return pResult->GetUnderlyingString(
        ppStringValue
	);
}