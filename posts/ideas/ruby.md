* ver prepend_features.rb

* modules can be instantiated

* bypass private

* koans: about_objects.rb:40
	 best explanation: https://stackoverflow.com/a/25744887
	 my friend tito found an integer with an even object_id
	 (0..).lazy.map(&:object_id).find(&:even?)
	 (0..2**64).bsearch { _1.object_id.even? }

* koans: last exercise with game logic decoupled from UI
  - https://github.com/rfelix/ruby_koans/blob/231159a37da2368fa0ba328bc99c6a811c9a1466/README.rdoc?plain=1#L14
  - https://github.com/pineman/code/blob/d74af52ecae7fa2ef32d115a737358c52739f935/ruby/koans/about_extra_credit.rb#L65
