
(xt-deftest rmh-elfeed-org-remove-elfeed-tag
  (xt-note "The elfeed tag should not be assigned to the feeds")
  (xt-should (equal
              (rmh-elfeed-org-cleanup-headlines '(("" elfeed tag1) ("" elfeed tag2)) 'elfeed)
              '(("" tag1) ("" tag2)))))

(xt-deftest rmh-elfeed-org-convert-headline-to-tagger-params
  (xt-note "Get paramemeters to create elfeed tagger")
  (xt-should (equal
              (rmh-elfeed-org-convert-headline-to-tagger-params '("entry-title:   hoi " tag0 tag1))
              '("hoi" (tag0 tag1)))))

(xt-deftest rmh-elfeed-org-trees-with-tag
  (xt-note "Use any number of trees tagged with \"elfeed\"")
  (xtd-should 'xt-trees-with-id-length
              ("test/fixture-no-ids-or-tags.org" 0)
              ("test/fixture-one-tag.org" 1)
              ("test/fixture-two-tags.org" 2)))

(xt-deftest rmh-elfeed-org-trees-with-id
  (xt-note "Use any number of trees with the id property \"elfeed\"")
  (xtd-should 'xt-trees-with-id-length
              ("test/fixture-no-ids-or-tags.org" 0)
              ("test/fixture-one-id2.org" 1)
              ("test/fixture-two-ids.org" 2)))

(xt-deftest rmh-elfeed-org-convert-tree-to-headlines
  (xt-note "Recusively include all feeds in a tree with their tags inherited from their parents")
  (xtd-should 'xt-feeds
              ("test/fixture-no-ids-or-tags.org" nil)
              ("test/fixture-one-tag.org"
               (("http1" elfeed tag1) ("http2" elfeed)))
              ("test/fixture-two-tags.org"
               (("http1" elfeed) ("http2" elfeed)))))

(xt-deftest rmh-elfeed-org-import-headlines-from-files
  (xt-note "Use all feeds in a multiple trees tagged with the \"elfeed\" tag and inherited their parent's tags")
  (xt-should (equal
              (rmh-elfeed-org-import-headlines-from-files '("test/fixture-one-tag.org" "test/fixture-two-ids.org") "elfeed")
              '(("http1" tag1) ("http2") ("http1" tag0 tag1) ("http2" tag2)))))

(xt-deftest rmh-elfeed-org-headlines-and-entrytitles-from-files
  (xt-note "Use all feeds in multiple trees tagged with the \"elfeed\" tag and inherited their parent's tags")
  (xt-should (equal
              (rmh-elfeed-org-import-headlines-from-files '("test/fixture-one-tag.org" "test/fixture-entry-title.org") "elfeed")
              '(("http1" tag1) ("http2") ("entry-title 1" tag1)))))

(xt-deftest rmh-elfeed-org-unique-headlines-and-entrytitles-from-files
  (xt-note "Should not return duplicate feeds, in this case two \"http2\" entries")
  (xt-should (equal
              (rmh-elfeed-org-import-headlines-from-files '("test/fixture-one-tag.org" "test/fixture-entry-title.org") "elfeed")
              '(("http1" tag1) ("http2") ("entry-title 1" tag1)))))

(xt-deftest rmh-elfeed-org-feeds-get-from-with-none-found
  (xt-note "Make sure no nil values instead of feeds are returned")
  (xt-should (equal
              (rmh-elfeed-org-import-headlines-from-files '("test/fixture-one-tag.org" "test/fixture-one-id-no-feeds.org") "elfeed")
              '(("http1" tag1) ("http2")))))

(xt-deftest rmh-elfeed-org-gets-inherited-tags2
  (xt-note "Get all headlines with inherited tags")
  (xtd-return= (lambda (_) (progn (org-mode)
                             (rmh-elfeed-org-convert-tree-to-headlines
                              (org-element-parse-buffer 'headline))))
               ("
* tree1 :elfeed:
** http1 :tag1:
** tree2 :tag2:
*** http2 :tag3:
** http4 :tag5:
* tree3 :elfeed:
** http3 :tag4:"
                '(("tree1" elfeed)
                  ("http1" elfeed tag1)
                  ("tree2" elfeed tag2)
                  ("http2" elfeed tag2 tag3)
                  ("http4" elfeed tag5)
                  ("tree3" elfeed)
                  ("http3" elfeed tag4)))))

(xt-deftest rmh-elfeed-org-test-filter
  (xt-note "Get headlines filtered")
  (xtd-return= (lambda (_) (progn (org-mode)
                             (rmh-elfeed-org-filter-relevant
                              (rmh-elfeed-org-convert-tree-to-headlines
                               (org-element-parse-buffer 'headline)
                               ))))
               ("
* tree1 :elfeed:
** http1 :tag1:
** entry-title :tag2:
*** http2 :tag3:
** http4 :tag5:
* tree3 :elfeed:
** http3 :tag4:"
                '(("http1" elfeed tag1)
                  ("entry-title" elfeed tag2)
                  ("http2" elfeed tag2 tag3)
                  ("http4" elfeed tag5)
                  ("http3" elfeed tag4)))))

(xt-deftest rmh-elfeed-org-test-cleanup
  (xt-note "The tag of the root tree node should not be included.")
  (xtd-return= (lambda (_) (progn (org-mode)
                             (rmh-elfeed-org-cleanup-headlines
                              (rmh-elfeed-org-convert-tree-to-headlines
                               (org-element-parse-buffer 'headline)
                               ) 'elfeed)))
               ("
* tree1 :elfeed:
** http1 :tag1:
** tree2 :tag2:
*** http2 :tag3:
** http4 :tag5:
* tree3 :elfeed:
** http3 :tag4:"
                '(("tree1")
                  ("http1" tag1)
                  ("tree2" tag2)
                  ("http2" tag2 tag3)
                  ("http4" tag5)
                  ("tree3")
                  ("http3" tag4)))))

(xt-deftest rmh-elfeed-org-test-flagging
  (xt-note "Wrongly formatted headlines are tagged to be ignored during import.")
  (xtd-setup= (lambda (_)
                (org-mode)
                (let ((parsed-org (org-element-parse-buffer 'headline)))
                  (delete-region (point-min) (point-max))
                  (insert (org-element-interpret-data
                           (rmh-elfeed-org-flag-headlines parsed-org)))))
              ("* tree1  :elfeed:\n-!-"
               "* tree1                                                       :_flag_:elfeed:\n-!-"
               )))
