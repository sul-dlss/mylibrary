import React from 'react';
import { shallow } from 'enzyme';
import Checkouts from 'Checkouts';

function createWrapper(props) {
  return shallow(
    <Checkouts
      apiUrl="http:www.example.com/api"
      {...props}
    />
  )
}

describe('Checkouts', () => {
  let wrapper;
  it('renders component', () => {
    wrapper = createWrapper();
    expect(wrapper.text()).toMatch('Api Requested: http:www.example.com/apiData');
  });
});
