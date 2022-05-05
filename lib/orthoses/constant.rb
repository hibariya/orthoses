# frozen_string_literal: true

module Orthoses
  class Constant
    def initialize(loader, if: nil, on_error: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
      @on_error = on_error
    end

    def call(env)
      cache = {}
      @loader.call(env).tap do |store|
        will_add_key_and_content = []
        store.each do |name, _|
          next if name == :Module
          next if name.start_with?('#<')

          begin
            base = Object.const_get(name)
          rescue NameError, ArgumentError
            # i18n/tests raise ArgumentError
            next
          end
          next unless base.kind_of?(Module)
          Orthoses::Util.each_const_recursive(base, on_error: @on_error) do |current, const, val|
            next if current.singleton_class?
            next if Util.module_name(current).nil?
            next if val.kind_of?(Module)
            next if cache[[current, const]]
            cache[[current, const]] = true

            rbs = Orthoses::Util.object_to_rbs(val)
            next unless rbs
            next unless @if.nil? || @if.call(current, const, val, rbs)

            will_add_key_and_content << [Util.module_name(current), "#{const}: #{rbs}"]
          end
        end
        will_add_key_and_content.each do |name, line|
          store[name] << line
        end
      end
    end
  end
end
