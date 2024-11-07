// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using Microsoft.VisualStudio.Debugger;
using Microsoft.VisualStudio.Debugger.CallStack;
using Microsoft.VisualStudio.Debugger.ComponentInterfaces;
using Microsoft.VisualStudio.Debugger.Evaluation;
using System;
using System.Collections.Generic;

namespace HelloWorld
{
    class EnumContextWrapperDataItem : DkmDataItem
    {
        // the enum context which we are extending
        public readonly DkmEvaluationResultEnumContext WrappedEnumContext;

        public EnumContextWrapperDataItem(DkmEvaluationResultEnumContext wrappedEnumContext)
        {
            WrappedEnumContext = wrappedEnumContext;
        }

        protected override void OnClose()
        {
            base.OnClose();
            WrappedEnumContext.Close();
        }
    }

    class EnumContextChildrenDataItem : DkmDataItem
    {

    }

    class EvalResultDataItem : DkmDataItem
    {
    }

    /// <summary>
    /// The one and only public class in the sample. This implements the IDkmCallStackFilter
    /// interface, which is how the sample is called.
    /// 
    /// Note that the list of interfaces implemented is defined here, and in 
    /// HelloWorld.vsdconfigxml. Both lists need to be the same.
    /// </summary>
    public class HelloWorldService : IDkmLanguageExpressionEvaluator
    {
        void IDkmLanguageExpressionEvaluator.EvaluateExpression(DkmInspectionContext inspectionContext, DkmWorkList workList, DkmLanguageExpression expression, DkmStackWalkFrame stackFrame, DkmCompletionRoutine<DkmEvaluateExpressionAsyncResult> completionRoutine)
        {
            inspectionContext.EvaluateExpression(workList, expression, stackFrame, completionRoutine);
        }

        void IDkmLanguageExpressionEvaluator.GetChildren(DkmEvaluationResult result, DkmWorkList workList, int initialRequestSize, DkmInspectionContext inspectionContext, DkmCompletionRoutine<DkmGetChildrenAsyncResult> completionRoutine)
        {
            EvalResultDataItem dataItem = result.GetDataItem<EvalResultDataItem>();
            if (dataItem != null)
            {
                // infinitely expand with the same result

                DkmEvaluationResultEnumContext enumContext = DkmEvaluationResultEnumContext.Create(
                    1,
                    result.StackFrame,
                    inspectionContext,
                    new EnumContextChildrenDataItem());

                DkmEvaluationResult[] items;
                if (initialRequestSize > 0)
                {
                    items = new DkmEvaluationResult[]
                    {
                        CreateOurEvalResult(inspectionContext, result.StackFrame)
                    };
                }
                else
                {
                    items = new DkmEvaluationResult[0];
                }

                completionRoutine(new DkmGetChildrenAsyncResult(items, enumContext));
            }
            else
            {
                result.GetChildren(workList, initialRequestSize, inspectionContext, completionRoutine);
            }
        }

        void IDkmLanguageExpressionEvaluator.GetFrameArguments(DkmInspectionContext inspectionContext, DkmWorkList workList, DkmStackWalkFrame frame, DkmCompletionRoutine<DkmGetFrameArgumentsAsyncResult> completionRoutine)
        {
            inspectionContext.GetFrameArguments(workList, frame, completionRoutine);
        }

        void IDkmLanguageExpressionEvaluator.GetFrameLocals(DkmInspectionContext inspectionContext, DkmWorkList workList, DkmStackWalkFrame stackFrame, DkmCompletionRoutine<DkmGetFrameLocalsAsyncResult> completionRoutine)
        {
            inspectionContext.GetFrameLocals(workList, stackFrame, result =>
            {
                try
                {
                    // this should throw for failing HRESULTs because concord is weird
                    _ = result.ErrorCode;

                    DkmEvaluationResultEnumContext newEnumContext = DkmEvaluationResultEnumContext.Create(
                        result.EnumContext.Count + 1,
                        result.EnumContext.StackFrame,
                        result.EnumContext.InspectionContext,
                        new EnumContextWrapperDataItem(result.EnumContext));

                    completionRoutine(new DkmGetFrameLocalsAsyncResult(newEnumContext));
                }
                catch (Exception e)
                {
                    completionRoutine(DkmGetFrameLocalsAsyncResult.CreateErrorResult(e));
                }

            });
        }

        void IDkmLanguageExpressionEvaluator.GetItems(DkmEvaluationResultEnumContext enumContext, DkmWorkList workList, int startIndex, int count, DkmCompletionRoutine<DkmEvaluationEnumAsyncResult> completionRoutine)
        {
            EnumContextWrapperDataItem dataItem = enumContext.GetDataItem<EnumContextWrapperDataItem>();
            if (dataItem != null)
            {
                if (startIndex < dataItem.WrappedEnumContext.Count)
                {
                    int endIdx = startIndex + count;
                    if (endIdx < dataItem.WrappedEnumContext.Count)
                    {
                        // we are still in the original enum context, we need to get the items from the original context
                        dataItem.WrappedEnumContext.GetItems(workList, startIndex, count, completionRoutine);
                    }
                    else
                    {
                        // we need to query items *and* insert ourselves at the end
                        dataItem.WrappedEnumContext.GetItems(workList, startIndex, count, result =>
                        {
                            try
                            {
                                _ = result.ErrorCode;
                                DkmEvaluationResult[] extendedResults = new DkmEvaluationResult[result.Items.Length + 1];
                                Array.Copy(result.Items, extendedResults, result.Items.Length);
                                extendedResults[extendedResults.Length - 1] = CreateOurEvalResult(enumContext.InspectionContext, enumContext.StackFrame);

                                completionRoutine(new DkmEvaluationEnumAsyncResult(extendedResults));
                            }
                            catch (Exception e)
                            {
                                completionRoutine(DkmEvaluationEnumAsyncResult.CreateErrorResult(e));
                                return;
                            }
                        });
                    }
                }
                else
                {
                    // we can provide our item directly, we are past the original enum context count
                    completionRoutine(new DkmEvaluationEnumAsyncResult(new[] { CreateOurEvalResult(enumContext.InspectionContext, enumContext.StackFrame) }));
                }
            }
            else
            {
                EnumContextChildrenDataItem childrenDataItem = enumContext.GetDataItem<EnumContextChildrenDataItem>();
                if (childrenDataItem != null)
                {
                    completionRoutine(new DkmEvaluationEnumAsyncResult(new[] { CreateOurEvalResult(enumContext.InspectionContext, enumContext.StackFrame) }));
                }
                else
                {
                    enumContext.GetItems(workList, startIndex, count, completionRoutine);
                }
            }
        }

        string IDkmLanguageExpressionEvaluator.GetUnderlyingString(DkmEvaluationResult result)
        {
            EvalResultDataItem dataItem = result.GetDataItem<EvalResultDataItem>();
            if (dataItem != null)
                throw new NotImplementedException();

            return result.GetUnderlyingString();
        }

        void IDkmLanguageExpressionEvaluator.SetValueAsString(DkmEvaluationResult result, string value, int timeout, out string errorText)
        {
            EvalResultDataItem dataItem = result.GetDataItem<EvalResultDataItem>();
            if (dataItem != null)
                throw new NotImplementedException();

            result.SetValueAsString(value, timeout, out errorText);
        }

        private static DkmEvaluationResult CreateOurEvalResult(DkmInspectionContext inspectionContext, DkmStackWalkFrame stackFrame)
        {
            return DkmSuccessEvaluationResult.Create(
                inspectionContext,
                stackFrame,
                "Hello, World!",
                "Hello, World!",
                DkmEvaluationResultFlags.Expandable,
                "0xDEADBEEF",
                null,
                "Fake!",
                DkmEvaluationResultCategory.Other,
                DkmEvaluationResultAccessType.None,
                DkmEvaluationResultStorageType.None,
                DkmEvaluationResultTypeModifierFlags.None,
                null,
                null,
                null,
                new EvalResultDataItem());
        }
    }
}
