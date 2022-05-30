module DuplicationCheckerTest
  def test_update_decl(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Foo
        def foo: () -> void
        attr_reader foo: untyped
        attr_accessor foo: untyped
        alias foo to_s
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 1
      t.error("expect drop duplicated method, bot #{decl.members.length}")
      return
    end
    unless decl.members.first.instance_of?(RBS::AST::Members::Alias)
      t.error("expect to remain alias, bot got #{decl.members.first.class}")
    end
  end

  def test_drop_known_method_definition(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Array[unchecked out Elem]
        def to_s: () -> void
        def sum: () -> void
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core method, bot #{decl.members.length}")
    end
  end
end
