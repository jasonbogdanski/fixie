﻿using System;
using System.Collections.Generic;
using Should;
using Xunit;

namespace Fixie.Tests
{
    public class RunnerTests
    {
        [Fact]
        public void ShouldExecuteAllCasesFoundByTheGivenConvention()
        {
            var convention = new StubConvention();
            var listener = new StubListener();
            var runner = new Runner(listener);

            var result = runner.Execute(convention);

            result.Total.ShouldEqual(5);
            result.Passed.ShouldEqual(3);
            result.Failed.ShouldEqual(2);
        }

        [Fact]
        public void ShouldLogFailedCaseExecution()
        {
            var convention = new StubConvention();
            var listener = new StubListener();
            var runner = new Runner(listener);

            runner.Execute(convention);

            listener.Entries.ShouldEqual("Throwing Case failed: Uncaught Exception!");
        }

        class StubConvention : Convention
        {
            public StubConvention()
            {
                Fixtures = new[]
                {
                    new StubFixture("Fixture 1",
                                    new StubCase("Throwing Case", () => { throw new Exception("Uncaught Exception!"); }),
                                    new StubCase("Failing Case", () => CaseResult.Fail(new Exception("Exception in Result!"))),
                                    new StubCase("Passing Case")),
                    new StubFixture("Fixture 2",
                                    new StubCase("Passing Case A"),
                                    new StubCase("Passing Case B"))
                };
            }

            public IEnumerable<Fixture> Fixtures { get; private set; }
        }

        class StubFixture : Fixture
        {
            public StubFixture(string name, params StubCase[] cases)
            {
                Name = name;
                Cases = cases;
            }

            public string Name { get; private set; }
            public IEnumerable<Case> Cases { get; private set; }
        }

        class StubCase : Case
        {
            readonly Func<CaseResult> execute;

            public StubCase(string name)
                : this(name, CaseResult.Pass) { }

            public StubCase(string name, Func<CaseResult> executionAction)
            {
                Name = name;
                execute = executionAction;
            }

            public string Name { get; private set; }

            public CaseResult Execute(Listener listener)
            {
                return execute();
            }
        }
    }
}