﻿namespace Fixie.Conventions
{
    public class ParameterSourceExpression
    {
        readonly Configuration config;

        public ParameterSourceExpression(Configuration config)
        {
            this.config = config;
        }

        public ParameterSourceExpression Add<TParameterSource>() where TParameterSource : ParameterSource
        {
            config.AddParameterSource<TParameterSource>();
            return this;
        }
    }
}